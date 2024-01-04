// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

interface ISmartAsset {
    function viewAsset() external view returns (string memory);

    function viewType() external view returns (string memory);
}
