// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import {SushiBarStrategy} from "../src/xsushi/SushiBarStrategy.sol";

contract SushiStrategyScript is Script {
    function run() public {
        address bentoBox = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966;
        address token = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2; // SUSHI
        address strategyExecutor = 0xC1056bDFE993340326D2efADaCFDFd6Fab5Eb13c;
        address owner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;
        address feeTo = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;
        uint256 STRATEGY_FEE = 99e16; // 99%

        address sushiBar = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        SushiBarStrategy sushiStrategy = new SushiBarStrategy(
            bentoBox,
            token,
            strategyExecutor,
            feeTo,
            owner,
            STRATEGY_FEE,
            sushiBar
        );

        console.log(address(sushiStrategy));
        vm.stopBroadcast();
    }
}
