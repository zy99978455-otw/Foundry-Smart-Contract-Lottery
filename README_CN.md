🎰 Foundry Smart Contract Lottery (Raffle)
这是一个基于 Solidity 和 Foundry 开发的去中心化彩票系统（Raffle）。该项目展示了如何构建一个自动化、随机性可验证的智能合约应用。

项目集成了 Chainlink VRF (Verifiable Random Function) 获取真随机数，并使用 Chainlink Automation 实现完全自动化的开奖流程。

🌟 核心功能 (Key Features)
去中心化参与：用户支付指定的 ETH 入场费即可参与抽奖。

真随机数生成：集成 Chainlink VRF v2.5，确保中奖者的产生是完全随机且不可篡改的。

自动化开奖：集成 Chainlink Automation，无需人工干预，达到时间间隔后自动触发开奖。

多环境支持：

本地开发 (Anvil)：使用 Mock 合约模拟 Chainlink 服务，零成本测试。

测试网 (Sepolia)：完整对接 Chainlink 真实预言机网络。

🛠️ 技术栈 (Tech Stack)
语言: Solidity (v0.8.19)

框架: Foundry (Forge, Cast, Anvil, Chisel)

预言机: Chainlink VRF & Chainlink Automation

工具库: solmate (用于 Mock LinkToken), foundry-devops (用于获取最新部署)

📂 项目结构与业务逻辑 (Project Architecture)
本项目不仅仅是一个简单的合约，还包含了一整套自动化的 DevOps 部署脚本。

1. 核心合约 (src/)
Raffle.sol: 核心业务逻辑。

enterRaffle(): 玩家买票逻辑。

checkUpkeep(): 检查是否满足开奖条件（时间到了？有钱吗？有人吗？）。

performUpkeep(): 触发开奖，请求随机数。

fulfillRandomWords(): 接收随机数并选出赢家。

2. 部署与配置 (script/)
为了解决 Chainlink 订阅管理的复杂性，我们编写了模块化的交互脚本：

HelperConfig.s.sol: 环境适配器。

根据 chainId 自动切换配置（Sepolia 用真实地址，Anvil 用 Mock 地址）。

统一管理 subscriptionId、gasLane、entranceFee 等参数。

Interactions.s.sol: 链上交互脚本库。

CreateSubscription: 如果没有订阅 ID，自动创建一个新的 Chainlink VRF 订阅。

FundSubscription: 自动给订阅 ID 充值 LINK 代币（本地使用 Mock 修改余额，测试网使用 transferAndCall）。

AddConsumer: 将部署好的 Raffle 合约地址注册到 Chainlink VRF 的消费者列表中，解决 InvalidConsumer 错误。

DeployRaffle.s.sol: 主部署脚本。

一键编排整个流程：创建订阅 -> 充值订阅 -> 部署合约 -> 添加消费者。

3. 本地模拟 (test/mocks/)
VRFCoordinatorV2_5Mock.sol: 模拟 Chainlink VRF 协调器，用于本地生成随机数。

LinkToken.sol: 模拟 LINK 代币（ERC-677），用于本地测试充值逻辑。

🚀 快速开始 (Quick Start)
1. 安装依赖
Bash
git clone <your-repo-url>
cd foundry-smart-contract-lottery
forge install
2. 编译
Bash
forge build
3. 运行测试
项目包含单元测试，覆盖了从部署到开奖的全流程。

Bash
forge test
4. 部署 (本地 Anvil)
脚本会自动检测并在本地部署 Mocks。

Bash
# 启动本地节点
anvil

# 在新终端运行脚本
forge script script/DeployRaffle.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key <YOUR_PRIVATE_KEY>
5. 部署 (Sepolia 测试网)
需要配置 .env 文件中的 SEPOLIA_RPC_URL 和 PRIVATE_KEY（以及 ETHERSCAN_API_KEY 用于验证）。

Bash
source .env
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --account default --broadcast --verify
🧪 测试策略 (Testing Strategy)
Unit Tests (RaffleTest.t.sol):

验证初始化状态（Open/Calculating）。

验证入场逻辑（金额不足回滚、记录玩家）。

验证 checkUpkeep 在不同状态下的返回值（时间未到、余额不足等）。

验证 performUpkeep 只能在条件满足时触发。

Fuzz Testing: 验证随机数返回后的赢家分配逻辑。

📝 学习笔记 (Project Learnings)
Foundry Scripting: 学会了如何用 Solidity 编写复杂的部署和管理脚本，替代了传统的 JS/TS 脚本。

Chainlink Integration: 深入理解了 VRF 的订阅模式（Subscription Manager），并通过代码实现了 Create -> Fund -> AddConsumer 的全自动化流程。

Testing: 掌握了 vm.warp (时间控制) 和 vm.roll (区块控制) 来测试与时间相关的合约逻辑。

Author: Zhaoyi  License: MIT