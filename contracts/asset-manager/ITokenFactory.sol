// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

interface ITokenFactory {
    function mintAsset(
        address receiver,
        address assetAddress
    ) external returns (uint256 tokenId);
}
