// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBentoBoxMinimal} from "../src/interfaces/IBentoBoxMinimal.sol";
import {AbraStkcvxcrvRenWBTCStrategy} from "../src/abra/AbraStkcvxcrvRenWBTCStrategy.sol";
import {AbraExtract} from "../src/abra/AbraExtract.sol";

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
    ERC20 stkcvxcrvRenWBTC_abra =
        ERC20(0xB65eDE134521F0EFD4E943c835F450137dC6E83e);

    AbraStkcvxcrvRenWBTCStrategy abraStkcvxcrvRenWBTCStrategy;
    AbraExtract abraExtract;

    function setUp() public {
        abraStkcvxcrvRenWBTCStrategy = new AbraStkcvxcrvRenWBTCStrategy(
            address(bentoBox),
            address(stkcvxcrvRenWBTC_abra),
            owner,
            feeTo,
            owner,
            STRATEGY_FEE,
            abraMultiSig
        );

        abraExtract = new AbraExtract(
            msg.sender,
            address(bentoBox),
            address(abraStkcvxcrvRenWBTCStrategy)
        );

        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(
            address(stkcvxcrvRenWBTC_abra),
            address(abraStkcvxcrvRenWBTCStrategy)
        );
        skip(2 weeks);
        bentoBox.setStrategy(
            address(stkcvxcrvRenWBTC_abra),
            address(abraStkcvxcrvRenWBTCStrategy)
        );
        bentoBox.setStrategyTargetPercentage(
            address(stkcvxcrvRenWBTC_abra),
            STRATEGY_TARGET_UTILIZATION
        );
        bentoBox.harvest(address(stkcvxcrvRenWBTC_abra), true, 0);
        vm.stopPrank();
    }

    function testLoopHarvest() public {
        vm.prank(owner);
        abraStkcvxcrvRenWBTCStrategy.setStrategyExecutor(
            address(abraExtract),
            true
        );

        bentoBox.harvest(address(stkcvxcrvRenWBTC_abra), true, 0);
        abraExtract.loopHarvest();
        uint256 abraMultiSigBalance = stkcvxcrvRenWBTC_abra.balanceOf(
            abraMultiSig
        );

        console.log("Loop Balance: ", abraMultiSigBalance);
    }

    function testAbraHarvest() public {
        bentoBox.harvest(address(stkcvxcrvRenWBTC_abra), true, 0);
        uint256 abraMultiSigBalance = stkcvxcrvRenWBTC_abra.balanceOf(
            abraMultiSig
        );

        console.log("Balance: ", abraMultiSigBalance);

        (, uint256 targetPercentage, uint256 balance) = bentoBox.strategyData(
            address(stkcvxcrvRenWBTC_abra)
        );

        assertEq(targetPercentage, STRATEGY_TARGET_UTILIZATION);
    }

    function testShouldExit() public {
        vm.startPrank(bentoBoxOwner);
        bentoBox.setStrategy(address(stkcvxcrvRenWBTC_abra), address(0));
        skip(2 weeks);
        bentoBox.setStrategy(address(stkcvxcrvRenWBTC_abra), address(0));

        uint256 elastic = bentoBox
            .totals(address(stkcvxcrvRenWBTC_abra))
            .elastic;
        uint256 base = bentoBox.totals(address(stkcvxcrvRenWBTC_abra)).base;
    }
}
