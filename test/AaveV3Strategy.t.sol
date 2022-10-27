// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBentoBoxMinimal} from "../src/interfaces/IBentoBoxMinimal.sol";
import {AaveV3Strategy} from "../src/aaveV3/AaveV3Strategy.sol";

contract AaveV3StrategyTest is Test {
    IBentoBoxMinimal bentoBox =
        IBentoBoxMinimal(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    address bentoBoxOwner = 0x1219Bfa3A499548507b4917E33F17439b67A2177;

    uint64 STRATEGY_TARGET_UTILIZATION = 70; // 6%

    uint256 STRATEGY_FEE = 99e16; // 99%

    address alice = address(0xABCD);
    address owner = address(0xDCBA);
    address feeTo = address(0x6969);

    ERC20 USDC = ERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);
    ERC20 OP = ERC20(0x4200000000000000000000000000000000000042);
    ERC20 aOptUSDC = ERC20(0x625E7708f30cA75bfd92586e17077590C60eb4cD);
    address aaveIncentiveController =
        0x929EC64c34a17401F460460D4B9390518E5B473e;
    address aaveV3Pool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    AaveV3Strategy aaveV3Strategy;

    function setUp() public {
        aaveV3Strategy = new AaveV3Strategy(
            address(bentoBox),
            address(USDC),
            owner,
            feeTo,
            owner,
            STRATEGY_FEE,
            aaveV3Pool,
            aaveIncentiveController
        );

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(USDC), address(aaveV3Strategy));
        skip(2 weeks);
        bentoBox.setStrategy(address(USDC), address(aaveV3Strategy));
        bentoBox.setStrategyTargetPercentage(
            address(USDC),
            STRATEGY_TARGET_UTILIZATION
        );
        bentoBox.harvest(address(USDC), true, 0);
        vm.stopPrank();
    }

    function testInitialHarvest() public {
        bentoBox.harvest(address(USDC), true, 0);

        (, uint256 targetPercentage, uint256 balance) = bentoBox.strategyData(
            address(USDC)
        );

        assertEq(targetPercentage, STRATEGY_TARGET_UTILIZATION);

        assertEq(balance, aOptUSDC.balanceOf(address(aaveV3Strategy)));
    }

    function testProfitHarvest() public {
        uint256 balanceInStrategyBefore = aOptUSDC.balanceOf(
            address(aaveV3Strategy)
        );

        skip(4 weeks);
        vm.roll(block.number + 1);

        uint256 balanceInStrategyAfter = aOptUSDC.balanceOf(
            address(aaveV3Strategy)
        );

        uint256 tokensEarned = balanceInStrategyAfter - balanceInStrategyBefore;

        assertGt(tokensEarned, 0);

        uint256 elasticBefore = bentoBox.totals(address(USDC)).elastic;

        vm.prank(owner);
        aaveV3Strategy.safeHarvest(elasticBefore, false, 0, true);

        uint256 elasticAfter = bentoBox.totals(address(USDC)).elastic;

        uint256 elasticDiff = elasticAfter - elasticBefore;

        assertGt(elasticDiff, 0);

        uint256 feeToBalance = USDC.balanceOf(feeTo);

        assertEq(feeToBalance, ((tokensEarned * STRATEGY_FEE) / 1e18));
        assertEq(tokensEarned, (elasticDiff + feeToBalance));
    }

    function testShouldExit() public {
        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(USDC), address(0));
        skip(2 weeks);
        bentoBox.setStrategy(address(USDC), address(0));

        assertEq(aOptUSDC.balanceOf(address(aaveV3Strategy)), 0);
    }
}
