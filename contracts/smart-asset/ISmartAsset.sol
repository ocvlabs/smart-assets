// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.19;

interface ISmartAsset {
    function getAssetData()
        external
        view
        returns (
            string memory assetName,
            string memory assetData,
            string memory assetType,
            address assetCreator
        );

    function viewAsset() external view returns (string memory);

    function viewType() external view returns (string memory);

    function viewCreator() external view returns (address);
}
