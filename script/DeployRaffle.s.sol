// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";


/**
 * @title DeployRaffle Script
 * @author ZhaoYi
 * @notice This script orchestrates the deployment of the Raffle contract.
 * @dev It automatically handles Chainlink VRF subscription creation, funding,
 * and consumer registration if they don't exist (useful for local testing).
 */
contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        // 1. Get Network Configuration
        // Instantiate the HelperConfig to get environment-specific variables (Sepolia vs Anvil)
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // 2. Auto-Setup Subcription (The "DevOps" Magic)
        // Logic: If subscriptionId is 0, it means we are on a local chain (Anvil)
        // or a fresh config, so we need to create one programmatically.
        if (config.subscriptionId == 0) {
            // Step A: Create a new Subscription
            CreateSubscription createSubscription = new CreateSubscription();
            config.subscriptionId = createSubscription.createSubscription(config.vrfCoordinator);

            // Step B: Fund the Subscription
            // (On Anvil this uses Mock LINK, on Sepolia this would use real LINK if configured)
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.linkToken);
        }

        // 3. Deploy the Contract
        // Only the deployment transaction needs to be broadcasted
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();


        // 4. Post-Deployment Setup: Add Consumer
        // Crucial Step: Register the newly deployed contract address with Chainlink VRF.
        // If we skip this, the contract cannot request random numbers (InvalidConsumer error).
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);

        return (raffle, helperConfig);
    }
}
