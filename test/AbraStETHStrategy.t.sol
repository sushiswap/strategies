// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBentoBoxMinimal} from "../src/interfaces/IBentoBoxMinimal.sol";
import {AbraStETHStrategy} from "../src/abra_stETH/AbraStETHStrategy.sol";

contract SushiStrategyTest is Test {
    IBentoBoxMinimal bentoBox =
        IBentoBoxMinimal(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    address bentoBoxOwner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;

    uint64 STRATEGY_TARGET_UTILIZATION = 95; // 95%

    uint256 STRATEGY_FEE = 0; // 0%

    address alice = address(0xABCD);
    address owner = address(0xDCBA);
    address feeTo = address(0x6969);

    address abraMultiSig = 0x5f0DeE98360d8200b20812e174d139A1a633EDd2;
    ERC20 yvCurve_stETH = ERC20(0xdCD90C7f6324cfa40d7169ef80b12031770B4325);

    AbraStETHStrategy abraStETHStrategy;

    function setUp() public {
        abraStETHStrategy = new AbraStETHStrategy(
            address(bentoBox),
            address(yvCurve_stETH),
            owner,
            feeTo,
            owner,
            STRATEGY_FEE,
            abraMultiSig
        );

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(
            address(yvCurve_stETH),
            address(abraStETHStrategy)
        );
        skip(2 weeks);
        bentoBox.setStrategy(
            address(yvCurve_stETH),
            address(abraStETHStrategy)
        );
        bentoBox.setStrategyTargetPercentage(
            address(yvCurve_stETH),
            STRATEGY_TARGET_UTILIZATION
        );
        bentoBox.harvest(address(yvCurve_stETH), true, 0);
        vm.stopPrank();
    }

    function testAbraHarvest() public {
        bentoBox.harvest(address(yvCurve_stETH), true, 0);
        uint256 abraMultiSigBalance = yvCurve_stETH.balanceOf(abraMultiSig);

        (, uint256 targetPercentage, uint256 balance) = bentoBox.strategyData(
            address(yvCurve_stETH)
        );

        assertEq(targetPercentage, STRATEGY_TARGET_UTILIZATION);
    }

    function testShouldExit() public {
        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(yvCurve_stETH), address(0));
        skip(2 weeks);
        bentoBox.setStrategy(address(yvCurve_stETH), address(0));

        uint256 elastic = bentoBox.totals(address(yvCurve_stETH)).elastic;
        uint256 base = bentoBox.totals(address(yvCurve_stETH)).base;
    }
}
