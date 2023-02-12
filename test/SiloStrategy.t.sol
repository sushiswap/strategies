// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {IBentoBoxMinimal} from "../src/interfaces/IBentoBoxMinimal.sol";
import {IEulerMarkets} from "../src/interfaces/euler/IEulerMarket.sol";
import {ISilo} from "../src/interfaces/silo/ISilo.sol";
import {IStrategy} from "../src/interfaces/IStrategy.sol";
import {SiloStrategy} from "../src/silo/SiloStrategy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract CounterTest is Test {
    IBentoBoxMinimal bentoBox =
        IBentoBoxMinimal(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    address bentoBoxOwner = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;

    address silo = 0x2eaf84b425822edF450fC5FdeEc085f2e5aDa98b; // cbETH Silo

    ERC20 strategyToken = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH

    ERC20 sToken = ERC20(0x315c9c216BBA84017C2204b248F29023c04C4e07); // sToken for cbETH Silo

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
            silo
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
}
