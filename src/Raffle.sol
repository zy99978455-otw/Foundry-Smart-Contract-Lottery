// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A simple Raffle contract
 * @author ZhaoYi
 * @notice This contract is for creating a sample raffle mechanism.
 * @dev Implements Chainlink VRF v2.5 and Chainlink Automation.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TranferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN,   //0
        CALCULATING //1
    }


    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // Duration of the lottery in seconds
    bytes32 private immutable i_keyHash;   // The gas lane key hash
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLine,    // Note: I corrected 'gasLine' to 'gasLine' for better naming convention
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLine;
        i_subscriptionId = subscriptionId;

        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    /**
     * @notice Enters the raffle by paying the entrance fee.
     * @dev Revert if the msg.value is less than the entrance fee of if the raffle is not open.
     */
    function enterRaffle() external payable {
        // 1. Check if the user sent enough ETH
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        // 2. Check if the raffle is currently open
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        // 3. Add the player to the array
        s_players.push(payable(msg.sender));

        // 4. Emit an event for indexing
        emit RaffleEntered(msg.sender);
    }
    /**
     * @dev This function is called by the Chainlink Automation nodes to see
     * if the lottery is ready to have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between raffle runs.
     * 2. The raffle is in the OPEN state.
     * 3. The contract has ETH (aka, players).
     * 4. (Implicit) The subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
     ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` returns true, this function is called automatically
     * and it kicks off the Chainlink VRF call to get a random number.
     */
    function performUpkeep(bytes calldata /* performData */) external {

        // Double check upkeepNeeded to prevent manual manipulation
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        // Update state so no one else can enter
        s_raffleState = RaffleState.CALCULATING;

        // Request random words from Chainlink VRF
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, 
            subId: i_subscriptionId, 
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit, 
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        // Request the random number
        s_vrfCoordinator.requestRandomWords(request);
    }

    /**
     * @dev This is the function that Chainlink VRF node calls to send the money to the winner.
     * @param randomWords The array of random numbers sent by VRF.
     */
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);   // Empty the player
        s_lastTimeStamp = block.timestamp;      // Reset countdown

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TranferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    } 


}
