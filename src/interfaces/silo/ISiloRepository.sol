// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface ISiloRepository {
    /// @notice Get Silo address of asset
    /// @param _asset address of asset
    /// @return address of corresponding Silo deployment
    function getSilo(address _asset) external view returns (address);

    function isSiloPaused(address _silo, address _asset)
        external
        view
        returns (bool);
}
