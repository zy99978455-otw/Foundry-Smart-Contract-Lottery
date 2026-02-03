// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";



contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        //1. 获取配置
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // 逻辑：如果没有订阅ID, 就自动创建一个
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            
            config.subscriptionId = createSubscription.createSubscription(config.vrfCoordinator);
        }

        //2. 部署合约
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
