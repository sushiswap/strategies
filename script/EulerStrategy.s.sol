// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import {EulerStrategy} from "../src/euler/EulerStrategy.sol";

contract EulerStrategyScript is Script {
    function run() public {
        address euler = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
        address eToken = 0xc8Bb5b9DF8Dcd2ef92622428843d48fF092C5439;
        address bentoBox = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966;
        address token = 0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9; // FTT
        address strategyExecutor = 0xC1056bDFE993340326D2efADaCFDFd6Fab5Eb13c;
        address owner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;
        address feeTo = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;

        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();
        EulerStrategy es = new EulerStrategy(
            bentoBox,
            token,
            strategyExecutor,
            feeTo,
            owner,
            euler,
            eToken
        );
        vm.stopBroadcast();
    }
}
