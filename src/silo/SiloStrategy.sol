// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {BaseStrategy} from "../BaseStrategy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {ISilo} from "../interfaces/silo/ISilo.sol";
import {EasyMath} from "./lib/EasyMath.sol";

/// @title Silo Strategy
/// @dev Lend tokens on Silo Finance
contract SiloStrategy is BaseStrategy {
    using SafeTransferLib for ERC20;
    using EasyMath for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    ISilo public immutable silo;
    ERC20 public immutable sToken;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the strategy configurations
    /// @param _bentoBox address of the bentobox
    /// @param _strategyToken address of the token in strategy
    /// @param _strategyExecutor address of the executor
    /// @param _feeTo address of the fee recipient
    /// @param _owner address of the owner of the strategy
    /// @param _fee fee of the strategy
    /// @param _silo Address of the Silo
    constructor(
        address _bentoBox,
        address _strategyToken,
        address _strategyExecutor,
        address _feeTo,
        address _owner,
        uint256 _fee,
        address _silo
    )
        BaseStrategy(
            _bentoBox,
            _strategyToken,
            _strategyExecutor,
            _feeTo,
            _owner,
            _fee
        )
    {
        silo = ISilo(_silo);
        sToken = ERC20(
            ISilo(_silo).assetStorage(strategyToken).collateralToken
        );
    }

    function _skim(uint256 amount) internal override {
        strategyToken.safeApprove(address(silo), amount);
        silo.deposit(address(strategyToken), amount, false);
    }

    function _harvest(uint256 balance)
        internal
        override
        returns (int256 amountAdded)
    {
        uint256 assetTotalDeposits = silo
            .assetStorage(strategyToken)
            .collateralOnlyDeposits;

        uint256 currentBalance = (sToken.balanceOf(address(this))).toAmount(
            assetTotalDeposits,
            sToken.totalSupply()
        );

        amountAdded = int256(currentBalance) - int256(balance);

        if (amountAdded > 0) {
            silo.withdraw(address(strategyToken), amountAdded, false);
        }
    }

    function _withdraw(uint256 amount) internal override {
        silo.withdraw(address(strategyToken), amount, false);
    }

    function _exit() internal override {
        uint256 assetTotalDeposits = silo
            .assetStorage(strategyToken)
            .collateralOnlyDeposits;

        uint256 tokenBalance = (sToken.balanceOf(address(this))).toAmount(
            assetTotalDeposits,
            sToken.totalSupply()
        );

        uint256 available = strategyToken.balanceOf(silo);

        if (tokenBalance <= available) {
            // If there are more tokens available than our full position, take all based on aToken balance (continue if unsuccessful).
            try
                silo.withdraw(address(strategyToken), tokenBalance, false)
            {} catch {}
        } else {
            // Otherwise redeem all available and take a loss on the missing amount (continue if unsuccessful).
            try
                silo.withdraw(address(strategyToken), available, false)
            {} catch {}
        }
    }

    function _harvestRewards() internal virtual override {}
}
