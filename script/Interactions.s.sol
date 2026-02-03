// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

// 引入Mock合约
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    // 1. 如果没有传参数，就去配置里找 vrfCoordinator
    function CreateSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        return createSubscription(config.vrfCoordinator);
    }

    // 2. 真正的创建逻辑
    function createSubscription(address vrfCoordinator) public returns (uint256) {
        console.log("Creating subscription on ChainID: ", block.chainid);

        vm.startBroadcast();


        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your sub Id is: ", subId);
        console.log("Please update subscriptionId in HelperConfig!");
        return subId;
    }

    function run() external returns (uint256) {
        return CreateSubscriptionUsingConfig();
    }
}