// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";


contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        //1. 获取配置
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit,
            address link,       // 如果你的配置里有 link，加上它
            uint256 deployerKey // 如果你的配置里有 key，加上它
        ) = helperConfig.activeNetworkConfig();

        //2. 部署合约
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        //3. 返回两个合约实例
        return (raffle, helperConfig);
    }
}