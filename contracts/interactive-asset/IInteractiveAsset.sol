// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

interface IInteractiveAsset {
    function getComposition()
        external
        view
        returns (
            string memory,
            address styleAddress,
            address bodyAddress,
            address settingAddress,
            address scriptAddress
        );

    function viewAsset() external view returns (string memory);

    function viewCreator() external view returns (address);
}
