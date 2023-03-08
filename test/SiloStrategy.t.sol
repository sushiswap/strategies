// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {IBentoBoxMinimal} from "../src/interfaces/IBentoBoxMinimal.sol";
import {ISilo} from "../src/interfaces/silo/ISilo.sol";
import {IStrategy} from "../src/interfaces/IStrategy.sol";
import {SiloStrategy} from "../src/silo/SiloStrategy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract CounterTest is Test {
    IBentoBoxMinimal bentoBox =
        IBentoBoxMinimal(0x74c764D41B77DBbb4fe771daB1939B00b146894A);

    address bentoBoxOwner = 0x978982772b8e4055B921bf9295c0d74eB36Bc54e;

    address silo = 0x7E38a9d2C99CaEf533E5D692ED8a2Ce4b478E585; // dpx Silo

    address siloAsset = 0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55; // dpx

    ERC20 strategyToken = ERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); // WETH

    ERC20 sToken = ERC20(0xa3419787E4be2F74F9021171Cb70D36B21Ad6F24); // sToken for dpx weth silo

    address siloLens = 0x2dD3fb3d8AaBdeCa8571BF5d5cC2969Cb563A6E9;

    address siloRepository = 0x8658047e48CC09161f4152c79155Dac1d710Ff0a;

    SiloStrategy siloStrategy;

    uint64 STRATEGY_TARGET_UTILIZATION = 10; // 10%

    uint256 STRATEGY_FEE = 99e16; // 99%

    address alice = address(0xABCD);
    address owner = address(0xDCBA);
    address feeTo = address(0x6969);

    function setUp() public {
        siloStrategy = new SiloStrategy(
            address(bentoBox),
            address(strategyToken),
            owner,
            feeTo,
            owner,
            STRATEGY_FEE,
            siloAsset,
            siloLens,
            siloRepository
        );

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(strategyToken), address(siloStrategy));
        skip(2 weeks);
        bentoBox.setStrategy(address(strategyToken), address(siloStrategy));
        bentoBox.setStrategyTargetPercentage(
            address(strategyToken),
            STRATEGY_TARGET_UTILIZATION
        );
        bentoBox.harvest(address(strategyToken), true, 0);
        vm.stopPrank();
    }

    function testInitialHarvest() public {
        bentoBox.harvest(address(strategyToken), true, 0);

        (, uint256 targetPercentage, uint256 balance) = bentoBox.strategyData(
            address(strategyToken)
        );

        assertEq(targetPercentage, STRATEGY_TARGET_UTILIZATION);
        assertEq(balance, siloStrategy.underlyingBalance() + 1);
    }

    function testProfitHarvest() public {
        uint256 balanceBefore = siloStrategy.underlyingBalance();

        skip(4 weeks);
        vm.roll(block.number + 1);

        ISilo(silo).accrueInterest(address(strategyToken));

        uint256 balanceAfter = siloStrategy.underlyingBalance();

        uint256 tokensEarned = balanceAfter - balanceBefore;

        assertGt(tokensEarned, 0);

        uint256 elasticBefore = bentoBox.totals(address(strategyToken)).elastic;

        vm.prank(owner);
        siloStrategy.safeHarvest(elasticBefore, false, 0, false);

        uint256 elasticAfter = bentoBox.totals(address(strategyToken)).elastic;

        uint256 elasticDiff = elasticAfter - elasticBefore;

        assertGt(elasticDiff, 0);

        uint256 feeToBalance = strategyToken.balanceOf(feeTo);

        assertEq(feeToBalance, ((tokensEarned * STRATEGY_FEE) / 1e18) - 1);
        assertEq(tokensEarned, (elasticDiff + feeToBalance) + 1);
    }

    function testShouldExit() public {
        uint256 elasticBefore = bentoBox.totals(address(strategyToken)).elastic;

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(strategyToken), address(0));
        skip(2 weeks);
        bentoBox.setStrategy(address(strategyToken), address(0));

        uint256 elasticAfter = bentoBox.totals(address(strategyToken)).elastic;

        uint256 diffElastic = elasticAfter - elasticBefore;

        assertGt(diffElastic, 0);

        assertEq(sToken.balanceOf(address(siloStrategy)), 0);
    }
}
