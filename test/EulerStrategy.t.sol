// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {IBentoBoxMinimal} from "../src/interfaces/IBentoBoxMinimal.sol";
import {IEulerMarkets} from "../src/interfaces/euler/IEulerMarket.sol";
import {IEulerEToken} from "../src/interfaces/euler/IEulerEToken.sol";
import {IStrategy} from "../src/interfaces/IStrategy.sol";
import {EulerStrategy} from "../src/euler/EulerStrategy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract CounterTest is Test {
    IBentoBoxMinimal bentoBox =
        IBentoBoxMinimal(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    address bentoBoxOwner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;

    ERC20 FTT = ERC20(0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9);
    address EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    IEulerMarkets EULER_MARKET =
        IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IEulerEToken eToken;

    EulerStrategy eulerStrategy;

    uint64 STRATEGY_TARGET_UTILIZATION = 6; // 6%

    uint256 STRATEGY_FEE = 99e16; // 99%

    address alice = address(0xABCD);
    address owner = address(0xDCBA);
    address feeTo = address(0x6969);

    function setUp() public {
        eToken = IEulerEToken(EULER_MARKET.underlyingToEToken(address(FTT)));

        eulerStrategy = new EulerStrategy(
            address(bentoBox),
            address(FTT),
            owner,
            feeTo,
            owner,
            EULER_MAINNET,
            address(eToken)
        );

        vm.prank(owner);
        eulerStrategy.setFee(STRATEGY_FEE);

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(FTT), address(eulerStrategy));
        skip(2 weeks);
        bentoBox.setStrategy(address(FTT), address(eulerStrategy));
        bentoBox.setStrategyTargetPercentage(
            address(FTT),
            STRATEGY_TARGET_UTILIZATION
        );
        bentoBox.harvest(address(FTT), true, 0);
        vm.stopPrank();
    }

    function testInitialHarvest() public {
        bentoBox.harvest(address(FTT), true, 0);

        (, uint256 targetPercentage, uint256 balance) = bentoBox.strategyData(
            address(FTT)
        );

        assertEq(targetPercentage, STRATEGY_TARGET_UTILIZATION);
        assertEq(
            balance,
            eToken.balanceOfUnderlying(address(eulerStrategy)) + 1
        );
    }

    function testProfitHarvest() public {
        uint256 balanceBefore = eToken.balanceOfUnderlying(
            address(eulerStrategy)
        );

        skip(4 weeks);
        vm.roll(block.number + 1);

        uint256 balanceAfter = eToken.balanceOfUnderlying(
            address(eulerStrategy)
        );

        uint256 tokensEarned = balanceAfter - balanceBefore;

        assertGt(tokensEarned, 0);

        uint256 elasticBefore = bentoBox.totals(address(FTT)).elastic;

        vm.prank(owner);
        eulerStrategy.safeHarvest(elasticBefore, false, 0, false);

        uint256 elasticAfter = bentoBox.totals(address(FTT)).elastic;

        uint256 elasticDiff = elasticAfter - elasticBefore;

        assertGt(elasticDiff, 0);

        uint256 feeToBalance = FTT.balanceOf(feeTo);

        assertEq(feeToBalance, ((tokensEarned * STRATEGY_FEE) / 1e18) - 1);
        assertEq(tokensEarned, (elasticDiff + feeToBalance) + 1);
    }

    function testShouldExit() public {
        uint256 elasticBefore = bentoBox.totals(address(FTT)).elastic;

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(FTT), address(0));
        skip(2 weeks);
        bentoBox.setStrategy(address(FTT), address(0));

        uint256 elasticAfter = bentoBox.totals(address(FTT)).elastic;

        uint256 diffElastic = elasticAfter - elasticBefore;

        assertGt(diffElastic, 0);

        assertEq(eToken.balanceOf(address(eulerStrategy)), 0);
    }
}
