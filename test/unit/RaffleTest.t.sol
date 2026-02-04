// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";



contract RaffleTest is Test {

    event RaffleEntered(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 automationUpdateInterval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        // 上帝特权，给PLAYER钱
        vm.deal(PLAYER, STARING_USER_BALANCE);

        // 先整体接住配置
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // 赋值给状态变量
        entranceFee = config.entranceFee;
        automationUpdateInterval = config.automationUpdateInterval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    // 测试 "没钱不让进"
    function testRaffleRevertsWHenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);

        raffle.enterRaffle();
    }

    // 测试 "交钱被记录"
    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        raffle.enterRaffle{value: entranceFee}();

        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {

        // 1. Arrange
        vm.prank(PLAYER);

        // 2. Act/Assert 启动检查：只检查第1个 indexed 参数，且必须是由 raffle 合约发出的
        vm.expectEmit(true, false, false, false, address(raffle));

        // 3. 发射期望的事件（标准答案）
        emit RaffleEntered(PLAYER);

        // 4. 调用真实函数
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // 1. Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // 导演：时间快进！
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // 触发开奖，这会把状态改为 CALCULATING
        raffle.performUpkeep("");

        // 2. Act / Assert (尝试在开奖期间买票， 预期报错)
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }
}