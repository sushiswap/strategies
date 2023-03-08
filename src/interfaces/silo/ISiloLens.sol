// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ISilo} from "./ISilo.sol";

interface ISiloLens {
    /// @notice returns total deposits with interest dynamically calculated at current block timestamp
    /// @param _asset asset address
    /// @return _totalDeposits total deposits amount with interest
    function totalDepositsWithInterest(ISilo _silo, address _asset)
        external
        view
        returns (uint256 _totalDeposits);
}
