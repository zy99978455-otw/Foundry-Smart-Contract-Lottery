# 🎰 Foundry Smart Contract Lottery (Raffle)

A decentralized lottery system (Raffle) built with **Solidity** and **Foundry**. 

This project demonstrates how to build an automated, verifiable, and tamper-proof smart contract application.

It integrates **Chainlink VRF** (Verifiable Random Function) for true randomness and uses **Chainlink Automation** to trigger the lottery draw automatically.

## 🌟 Key Features
* **Decentralized Participation**: Users can enter the lottery by paying a specific entrance fee in ETH.

* **Verifiable Randomness**: Integrates Chainlink VRF v2.5 to ensure the winner selection process is provably random and tamper-proof.

* **Automated Execution**: Integrates Chainlink Automation to automatically trigger the winner selection once the time interval has passed, without manual intervention.

### 📂Multi-Environment Support:

* **Local Development (Anvil)**: Uses Mock contracts to simulate Chainlink services for zero-cost local testing.

* **Testnet (Sepolia)**: Fully compatible with the live Chainlink oracle network.

## 🛠️ Tech Stack
* **Language**: Solidity (v0.8.19)

* **Framework**: Foundry (Forge, Cast, Anvil, Chisel)

* **Oracles**: Chainlink VRF & Chainlink Automation

* **Libraries**: solmate (for Mock LinkToken), foundry-devops (for retrieving latest deployments)

## 📂 Project Architecture
This project is more than just a smart contract; it includes a comprehensive suite of automated DevOps deployment scripts.

### 1. Core Contracts (src/)
* **Raffle.sol**: The core business logic.

* **enterRaffle()**: Logic for players to buy tickets.

* **checkUpkeep()**: Checks if the conditions for a draw are met.

* **performUpkeep()**: Triggers the draw and requests a random number.

* **fulfillRandomWords()**: Receives the random number and picks the winner.

### 2. Deployment & Scripts (script/)
To handle the complexity of Chainlink subscription management, we utilize modular interaction scripts:

* **`HelperConfig.s.sol`**: Environment Adapter.
    * Automatically switches configuration based on chainId (Real addresses for Sepolia, Mocks for Anvil).

    * Manages parameters like subscriptionId, gasLane, and entranceFee.

* **`Interactions.s.sol`**: On-Chain Interaction Library.

* **`CreateSubscription`**: Programmatically creates a new Chainlink VRF subscription if one doesn't exist.

* **`FundSubscription`**: Funds the subscription with LINK tokens (Uses Mock minting locally, uses transferAndCall on testnets).

* **`AddConsumer`**: Registers the deployed Raffle contract to the VRF Consumer list (Resolves the InvalidConsumer error).

* **`DeployRaffle.s.sol`**: Main Deployment Script.

* **`Orchestrates the entire flow`**: Create Sub -> Fund Sub -> Deploy Contract -> Add Consumer.

### 3. Local Mocks (test/mocks/)
* **VRFCoordinatorV2_5Mock.sol**: Simulates the Chainlink VRF Coordinator for local randomness generation.

* **LinkToken.sol**: Simulates the LINK token (ERC-677 compliant) for local funding tests.

## 🚀 Quick Start
### 1. Install Dependencies
```Bash
git clone https://github.com/zy99978455-otw/Foundry-Smart-Contract-Lottery.git
cd foundry-smart-contract-lottery
forge install
```
### 2. Compile
```Bash
forge build
```
### 3. Run Tests
The project includes unit tests covering the entire flow from deployment to winner selection.

```Bash
forge test
```
### 4. Deploy (Local Anvil)
The script detects the local chain and deploys Mocks automatically.


# 1. Start a local node in a separate terminal
```Bash
anvil
```

# 2. Run the deployment script
```Bash
forge script script/DeployRaffle.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key <YOUR_PRIVATE_KEY>
```

### 5. Deploy (Sepolia Testnet)
Create a .env file and configure SEPOLIA_RPC_URL, PRIVATE_KEY, and optionally ETHERSCAN_API_KEY for verification.

```Bash
source .env
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --account default --broadcast --verify
```

## 🧪 Testing Strategy
### Unit Tests (RaffleTest.t.sol):

* **Verify initialization state (Open/Calculating)**

* **Verify entrance logic (Revert on insufficient funds, record players)**

* **Verify checkUpkeep returns correct values under various conditions (time passed, balance checks)**

* **Verify performUpkeep only triggers when conditions are met**

### Fuzz Testing:

* **Validate winner selection logic with random inputs**


---
* **Author**: ZhaoYi 
* **License**: MIT