// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A simple Raffle contract
 * @author ZhaoYi
 * @notice This contract implements a simple raffle system.
 * @dev Implements Chainlink VRF v2.5 and Chainlink Automation.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle_TranferFailed();
    error Raffle_RaffleNotOpen();

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
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLine,
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

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter raffle");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle);
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle(); // gas 效率最高
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
     ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        // 1. 检查状态是否为 OPEN
        bool isOpen = RaffleState.OPEN == s_raffleState;
        // 2. 检查时间间隔是否满足
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        // 3. 检查是否有玩家
        bool hasPlayers = s_players.length > 0;
        // 4. 检查是否有余额
        bool hasBalance = address(this).balance > 0;

        // 只有 4 个条件同时满足，才通知节点：该干活了！(upkeepNeeded = true)
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);

        // performData 我们暂时用不到，返回空值即可
        return (upkeepNeeded, "0x0");
    }

    // Get a random number
    // Use random number to pick a player
    // Be automatically called
    function performUpkeep(bytes calldata /* performData */) external {

        // 1. 调用 checkUpkeep 进行全面检查
        (bool upkeepNeeded, ) = checkUpkeep("");
        // 2. 如果不需要开奖，抛出带参数的详细错误
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // 3. 发送请求
        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, //用哪一组随机节点
            subId: i_subscriptionId,    //谁付钱？
            requestConfirmations: REQUEST_CONFIRMATIONS,    //你能等多久？
            callbackGasLimit: i_callbackGasLimit,   //我最多允许你用多少 gas 调我
            numWords: NUM_WORDS,    //你要几个随机数
            extraArgs: VRFV2PlusClient._argsToBytes(    //可扩展协议位
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);   //清空玩家
        s_lastTimeStamp = block.timestamp;      //重置倒计时

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TranferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }


}
