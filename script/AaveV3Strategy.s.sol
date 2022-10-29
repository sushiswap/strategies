// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import {AaveV3Strategy} from "../src/aaveV3/AaveV3Strategy.sol";

contract AaveV3StrategyScript is Script {
    function run() public {
        address bentoBox = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
        address strategyExecutor = 0xC1056bDFE993340326D2efADaCFDFd6Fab5Eb13c;
        address owner = 0x1219Bfa3A499548507b4917E33F17439b67A2177;
        address feeTo = 0x1219Bfa3A499548507b4917E33F17439b67A2177;
        uint256 STRATEGY_FEE = 99e16; // 99%

        address aaveIncentiveController = 0x929EC64c34a17401F460460D4B9390518E5B473e;
        address aaveV3Pool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

        address[] memory tokens = new address[](6);

        tokens[0] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI
        tokens[1] = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9; // sUSD
        tokens[2] = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607; // USDC
        tokens[3] = 0x4200000000000000000000000000000000000006; // WETH
        tokens[4] = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58; // USDT
        tokens[5] = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; // WBTC

        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        for (uint i; i < tokens.length; i++) {
            AaveV3Strategy a = new AaveV3Strategy(
                bentoBox,
                tokens[i],
                strategyExecutor,
                feeTo,
                owner,
                STRATEGY_FEE,
                aaveV3Pool,
                aaveIncentiveController
            );
            console.log(address(a));
        }

        vm.stopBroadcast();
    }
}
