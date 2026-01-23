// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

/**
 * @title A simple Raffle contract
 * @author ZhaoYi
 * @notice This contract implements a simple raffle system.
 * @dev Implements Chainlink VRF v2.5
 */
contract Raffle {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    // @dev: The duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /* Events */
    event RaffleEntered(address indexed player);


    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable{

        // require(msg.value >= i_entranceFee, "Not enough ETH to enter raffle");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle);
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();     // gas 效率最高
        }
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    // Get a random number
    // Use random number to pick a player
    // Be automatically called
    function pickWinner() external {
        // Check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
    }

    /** Getter Functions */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}