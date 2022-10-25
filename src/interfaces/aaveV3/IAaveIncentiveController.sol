// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IAaveIncentivesController
 * @author Aave
 * @notice Defines the basic interface for an Aave Incentives Controller.
 **/
interface IAaveIncentivesController {
    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);
}
