// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import {AbraStETHStrategy} from "../src/abra/AbraStETHStrategy.sol";
import {AbraStkcvxcrvRenWBTCStrategy} from "../src/abra/AbraStkcvxcrvRenWBTCStrategy.sol";
import {AbraExtract} from "../src/abra/AbraExtract.sol";

contract AbraStrategyScript is Script {
    function run() public {
        address bentoBox = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966;

        address yvCurve_stETH = 0xdCD90C7f6324cfa40d7169ef80b12031770B4325; // yvCurve_stETH
        address stkcvxcrvRenWBTC_abra = 0xB65eDE134521F0EFD4E943c835F450137dC6E83e; // stkcvxcrvRenWBTC_abra

        address abraMultiSig = 0xDF2C270f610Dc35d8fFDA5B453E74db5471E126B;

        address strategyExecutor = 0xC1056bDFE993340326D2efADaCFDFd6Fab5Eb13c;
        address owner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;
        address feeTo = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;

        uint256 STRATEGY_FEE = 0; // 0%

        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        // yvCurve_stETH
        AbraStETHStrategy abraStETHStrategy = new AbraStETHStrategy(
            bentoBox,
            yvCurve_stETH,
            owner,
            feeTo,
            owner,
            STRATEGY_FEE,
            abraMultiSig
        );

        AbraExtract abraExtract0 = new AbraExtract(
            strategyExecutor,
            bentoBox,
            address(abraStETHStrategy)
        );

        console.log("AbraStETHStrategy:", address(abraStETHStrategy));
        console.log("AbraExtract0:", address(abraExtract0));

        // stkcvxcrvRenWBTC_abra
        AbraStkcvxcrvRenWBTCStrategy abraStkcvxcrvRenWBTCStrategy = new AbraStkcvxcrvRenWBTCStrategy(
                bentoBox,
                stkcvxcrvRenWBTC_abra,
                owner,
                feeTo,
                owner,
                STRATEGY_FEE,
                abraMultiSig
            );

        AbraExtract abraExtract1 = new AbraExtract(
            strategyExecutor,
            bentoBox,
            address(abraStkcvxcrvRenWBTCStrategy)
        );

        console.log(
            "AbraStkcvxcrvRenWBTCStrategy:",
            address(abraStkcvxcrvRenWBTCStrategy)
        );
        console.log("AbraExtract1:", address(abraExtract1));

        vm.stopBroadcast();
    }
}
