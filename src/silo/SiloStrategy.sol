// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {BaseStrategy} from "../BaseStrategy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {ISilo} from "../interfaces/silo/ISilo.sol";
import {ISiloLens} from "../interfaces/silo/ISiloLens.sol";
import {ISiloRepository} from "../interfaces/silo/ISiloRepository.sol";
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
    ISiloLens public immutable siloLens;
    ISiloRepository public immutable siloRepository;
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
    /// @param _siloAsset Address of the Silo Asset
    /// @param _siloLens Address of the Silo Lens
    /// @param _siloRepository Address of the Silo Repository
    constructor(
        address _bentoBox,
        address _strategyToken,
        address _strategyExecutor,
        address _feeTo,
        address _owner,
        uint256 _fee,
        address _siloAsset,
        address _siloLens,
        address _siloRepository
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
        siloLens = ISiloLens(_siloLens);
        siloRepository = ISiloRepository(_siloRepository);
        silo = ISilo(siloRepository.getSilo(_siloAsset));
        require(
            address(silo) != address(0) &&
                !siloRepository.isSiloPaused(address(silo), _strategyToken)
        );
        sToken = ERC20(
            ISilo(silo).assetStorage(_strategyToken).collateralToken
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
        uint256 assetTotalDeposits = siloLens.totalDepositsWithInterest(
            silo,
            address(strategyToken)
        );

        uint256 currentBalance = (sToken.balanceOf(address(this))).toAmount(
            assetTotalDeposits,
            sToken.totalSupply()
        );

        amountAdded = int256(currentBalance) - int256(balance);

        if (amountAdded > 0) {
            silo.withdraw(address(strategyToken), uint256(amountAdded), false);
        }
    }

    function _withdraw(uint256 amount) internal override {
        silo.withdraw(address(strategyToken), amount, false);
    }

    function _exit() internal override {
        uint256 assetTotalDeposits = siloLens.totalDepositsWithInterest(
            silo,
            address(strategyToken)
        );

        uint256 tokenBalance = (sToken.balanceOf(address(this))).toAmount(
            assetTotalDeposits,
            sToken.totalSupply()
        );

        uint256 available = strategyToken.balanceOf(address(silo)) -
            silo.assetStorage(address(strategyToken)).collateralOnlyDeposits;

        if (tokenBalance <= available) {
            // If there are more tokens available than our full position, take all based on sToken balance (continue if unsuccessful).
            try
                silo.withdraw(address(strategyToken), type(uint256).max, false)
            {} catch {}
        } else {
            // Otherwise redeem all available and take a loss on the missing amount (continue if unsuccessful).
            try
                silo.withdraw(address(strategyToken), available, false)
            {} catch {}
        }
    }

    function _harvestRewards() internal virtual override {}

    function underlyingBalance()
        external
        view
        returns (uint256 currentBalance)
    {
        uint256 assetTotalDeposits = siloLens.totalDepositsWithInterest(
            silo,
            address(strategyToken)
        );

        currentBalance = (sToken.balanceOf(address(this))).toAmount(
            assetTotalDeposits,
            sToken.totalSupply()
        );
    }
}
