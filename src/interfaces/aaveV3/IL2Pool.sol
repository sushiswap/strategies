// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IL2Pool
 * @author Aave
 * @notice Defines the basic extension interface for an L2 Aave Pool.
 **/
interface IL2Pool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Calldata efficient wrapper of the supply function on behalf of the caller
     * @param args Arguments for the supply function packed in one bytes32
     *    96 bits       16 bits         128 bits      16 bits
     * | 0-padding | referralCode | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     */
    function supply(bytes32 args) external;

    /**
     * @notice Calldata efficient wrapper of the supplyWithPermit function on behalf of the caller
     * @param args Arguments for the supply function packed in one bytes32
     *    56 bits    8 bits         32 bits           16 bits         128 bits      16 bits
     * | 0-padding | permitV | shortenedDeadline | referralCode | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     * @param r The R parameter of ERC712 permit sig
     * @param s The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        bytes32 args,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Calldata efficient wrapper of the withdraw function, withdrawing to the caller
     * @param args Arguments for the withdraw function packed in one bytes32
     *    112 bits       128 bits      16 bits
     * | 0-padding | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     */
    function withdraw(bytes32 args) external;

    /**
     * @notice Calldata efficient wrapper of the borrow function, borrowing on behalf of the caller
     * @param args Arguments for the borrow function packed in one bytes32
     *    88 bits       16 bits             8 bits                 128 bits       16 bits
     * | 0-padding | referralCode | shortenedInterestRateMode | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     */
    function borrow(bytes32 args) external;

    /**
     * @notice Calldata efficient wrapper of the repay function, repaying on behalf of the caller
     * @param args Arguments for the repay function packed in one bytes32
     *    104 bits             8 bits               128 bits       16 bits
     * | 0-padding | shortenedInterestRateMode | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     * @return The final amount repaid
     */
    function repay(bytes32 args) external returns (uint256);

    /**
     * @notice Calldata efficient wrapper of the repayWithPermit function, repaying on behalf of the caller
     * @param args Arguments for the repayWithPermit function packed in one bytes32
     *    64 bits    8 bits        32 bits                   8 bits               128 bits       16 bits
     * | 0-padding | permitV | shortenedDeadline | shortenedInterestRateMode | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     * @param r The R parameter of ERC712 permit sig
     * @param s The S parameter of ERC712 permit sig
     * @return The final amount repaid
     */
    function repayWithPermit(
        bytes32 args,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /**
     * @notice Calldata efficient wrapper of the repayWithATokens function
     * @param args Arguments for the repayWithATokens function packed in one bytes32
     *    104 bits             8 bits               128 bits       16 bits
     * | 0-padding | shortenedInterestRateMode | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     * @return The final amount repaid
     */
    function repayWithATokens(bytes32 args) external returns (uint256);

    /**
     * @notice Calldata efficient wrapper of the swapBorrowRateMode function
     * @param args Arguments for the swapBorrowRateMode function packed in one bytes32
     *    232 bits            8 bits             16 bits
     * | 0-padding | shortenedInterestRateMode | assetId |
     * @dev assetId is the index of the asset in the reservesList.
     */
    function swapBorrowRateMode(bytes32 args) external;

    /**
     * @notice Calldata efficient wrapper of the rebalanceStableBorrowRate function
     * @param args Arguments for the rebalanceStableBorrowRate function packed in one bytes32
     *    80 bits      160 bits     16 bits
     * | 0-padding | user address | assetId |
     * @dev assetId is the index of the asset in the reservesList.
     */
    function rebalanceStableBorrowRate(bytes32 args) external;

    /**
     * @notice Calldata efficient wrapper of the setUserUseReserveAsCollateral function
     * @param args Arguments for the setUserUseReserveAsCollateral function packed in one bytes32
     *    239 bits         1 bit       16 bits
     * | 0-padding | useAsCollateral | assetId |
     * @dev assetId is the index of the asset in the reservesList.
     */
    function setUserUseReserveAsCollateral(bytes32 args) external;

    /**
     * @notice Calldata efficient wrapper of the liquidationCall function
     * @param args1 part of the arguments for the liquidationCall function packed in one bytes32
     *    64 bits      160 bits       16 bits         16 bits
     * | 0-padding | user address | debtAssetId | collateralAssetId |
     * @param args2 part of the arguments for the liquidationCall function packed in one bytes32
     *    127 bits       1 bit             128 bits
     * | 0-padding | receiveAToken | shortenedDebtToCover |
     * @dev the shortenedDebtToCover is cast to 256 bits at decode time,
     * if type(uint128).max the value will be expanded to type(uint256).max
     */
    function liquidationCall(bytes32 args1, bytes32 args2) external;
}
