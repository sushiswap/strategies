// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBentoBoxMinimal} from "../src/interfaces/IBentoBoxMinimal.sol";
import {ISushiBar} from "../src/interfaces/xsushi/ISushiBar.sol";
import {SushiBarStrategy} from "../src/xsushi/SushiBarStrategy.sol";

contract SushiStrategyTest is Test {
    IBentoBoxMinimal bentoBox =
        IBentoBoxMinimal(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    address bentoBoxOwner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;

    uint64 STRATEGY_TARGET_UTILIZATION = 70; // 6%

    uint256 STRATEGY_FEE = 99e16; // 99%

    address alice = address(0xABCD);
    address owner = address(0xDCBA);
    address feeTo = address(0x6969);

    ERC20 sushiToken = ERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    address sushiBar = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    SushiBarStrategy sushiBarStrategy;

    function setUp() public {
        sushiBarStrategy = new SushiBarStrategy(
            address(bentoBox),
            address(sushiToken),
            owner,
            feeTo,
            owner,
            STRATEGY_FEE,
            sushiBar
        );

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(sushiToken), address(sushiBarStrategy));
        skip(2 weeks);
        bentoBox.setStrategy(address(sushiToken), address(sushiBarStrategy));
        bentoBox.setStrategyTargetPercentage(
            address(sushiToken),
            STRATEGY_TARGET_UTILIZATION
        );
        bentoBox.harvest(address(sushiToken), true, 0);
        vm.stopPrank();
    }

    function testInitialHarvest() public {
        bentoBox.harvest(address(sushiToken), true, 0);

        (, uint256 targetPercentage, uint256 balance) = bentoBox.strategyData(
            address(sushiToken)
        );

        assertEq(targetPercentage, STRATEGY_TARGET_UTILIZATION);
        uint256 sushiBalanceInStrategy = (ERC20(sushiBar).balanceOf(
            address(sushiBarStrategy)
        ) * (sushiToken.balanceOf(sushiBar))) /
            ISushiBar(sushiBar).totalSupply();

        assertEq(balance, sushiBalanceInStrategy + 1);
    }

    function testProfitHarvest() public {
        uint256 sushiBalanceInStrategyBefore = (ERC20(sushiBar).balanceOf(
            address(sushiBarStrategy)
        ) * (sushiToken.balanceOf(sushiBar))) /
            ISushiBar(sushiBar).totalSupply();

        // serve some freshly made sushi
        deal(
            address(sushiToken),
            sushiBar,
            sushiToken.balanceOf(sushiBar) + 10000e18
        );

        uint256 sushiBalanceInStrategyAfter = (ERC20(sushiBar).balanceOf(
            address(sushiBarStrategy)
        ) * (sushiToken.balanceOf(sushiBar))) /
            ISushiBar(sushiBar).totalSupply();

        uint256 tokensEarned = sushiBalanceInStrategyAfter -
            sushiBalanceInStrategyBefore;

        assertGt(tokensEarned, 0);

        uint256 elasticBefore = bentoBox.totals(address(sushiToken)).elastic;

        vm.prank(owner);
        sushiBarStrategy.safeHarvest(elasticBefore, false, 0, false);

        uint256 elasticAfter = bentoBox.totals(address(sushiToken)).elastic;

        uint256 elasticDiff = elasticAfter - elasticBefore;

        assertGt(elasticDiff, 0);

        uint256 feeToBalance = sushiToken.balanceOf(feeTo);

        assertEq(feeToBalance, ((tokensEarned * STRATEGY_FEE) / 1e18));
        assertEq(tokensEarned, (elasticDiff + feeToBalance));
    }

    function testShouldExit() public {
        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(sushiToken), address(0));
        skip(2 weeks);
        bentoBox.setStrategy(address(sushiToken), address(0));

        assertEq(ERC20(sushiBar).balanceOf(address(sushiBarStrategy)), 0);
    }
}
