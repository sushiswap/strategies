// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import {EulerStrategy} from "../src/euler/EulerStrategy.sol";

contract EulerStrategyScript is Script {
    function run() public {
        address euler = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
        address eToken = 0xcf31501179eef59c8B6722e99489f7035b53F83E;
        address bentoBox = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966;
        address token = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3; // MIM
        address strategyExecutor = 0xC1056bDFE993340326D2efADaCFDFd6Fab5Eb13c;
        address owner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;
        address feeTo = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;
        uint256 STRATEGY_FEE = 99e16; // 99%

        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();
        EulerStrategy es = new EulerStrategy(
            bentoBox,
            token,
            strategyExecutor,
            feeTo,
            owner,
            STRATEGY_FEE,
            euler,
            eToken
        );
        console.log(address(es));
        vm.stopBroadcast();
    }
}
