// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {BaseStrategy} from "../BaseStrategy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IL2Pool} from "../interfaces/aaveV3/IL2Pool.sol";
import {IAaveIncentivesController} from "../interfaces/aaveV3/IAaveIncentiveController.sol";

/// @title AaveV3 Strategy
/// @dev Lend token on AaveV3
contract AaveV3Strategy is BaseStrategy {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    IL2Pool public immutable aaveV3Pool;
    IAaveIncentivesController public immutable incentiveController;
    ERC20 public immutable aToken;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the strategy configurations
    /// @param _bentoBox address of the bentobox
    /// @param _strategyToken address of the token in strategy
    /// @param _strategyExecutor address of the executor
    /// @param _feeTo address of the fee recipient
    /// @param _owner address of the owner of the strategy
    /// @param _aaveV3Pool address of aave pool
    /// @param _aToken address of pool token
    /// @param _incentiveController address of incentive / reward controller
    constructor(
        address _bentoBox,
        address _strategyToken,
        address _strategyExecutor,
        address _feeTo,
        address _owner,
        address _aaveV3Pool,
        address _aToken,
        address _incentiveController
    )
        BaseStrategy(
            _bentoBox,
            _strategyToken,
            _strategyExecutor,
            _feeTo,
            _owner
        )
    {
        aaveV3Pool = IL2Pool(_aaveV3Pool);
        aToken = ERC20(_aToken);
        incentiveController = IAaveIncentivesController(_incentiveController);
    }

    function _skim(uint256 amount) internal override {
        strategyToken.safeApprove(address(aaveV3Pool), amount);
        aaveV3Pool.supply(address(strategyToken), amount, address(this), 0);
    }

    function _harvest(uint256 balance)
        internal
        override
        returns (int256 amountAdded)
    {
        uint256 currentBalance = aToken.balanceOf(address(this));
        amountAdded = int256(currentBalance) - int256(balance); // Reasonably assume the values won't overflow.
        if (amountAdded > 0)
            aaveV3Pool.withdraw(
                address(strategyToken),
                uint256(amountAdded),
                address(this)
            );
    }

    function _withdraw(uint256 amount) internal override {
        aaveV3Pool.withdraw(address(strategyToken), amount, address(this));
    }

    function _exit() internal override {
        uint256 tokenBalance = aToken.balanceOf(address(this));
        uint256 available = strategyToken.balanceOf(address(aToken));
        if (tokenBalance <= available) {
            // If there are more tokens available than our full position, take all based on aToken balance (continue if unsuccessful).
            try
                aaveV3Pool.withdraw(
                    address(strategyToken),
                    tokenBalance,
                    address(this)
                )
            {} catch {}
        } else {
            // Otherwise redeem all available and take a loss on the missing amount (continue if unsuccessful).
            try
                aaveV3Pool.withdraw(
                    address(strategyToken),
                    available,
                    address(this)
                )
            {} catch {}
        }
    }

    function _harvestRewards() internal virtual override {
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(aToken);
        incentiveController.claimAllRewards(rewardTokens, feeTo);
    }
}
