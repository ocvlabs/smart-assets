// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

import {ISmartAsset} from "./ISmartAsset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SmartAsset is ISmartAsset, Ownable {
    string private _asset;
    string private _type;

    bool isPublic = false;

    mapping(address assetViewer => bool) private _hasAccess;

    constructor(
        string memory assetData,
        bool isProcessed,
        string memory assetType
    ) {
        if (isProcessed) {
            _setAssetData(assetData, assetType);
        } else {
            _processAssetData(assetData, assetType);
        }
    }

    modifier hasAccess(address assetViewer) {
        _checkAccess(assetViewer);
        _;
    }

    function viewAsset()
        external
        view
        hasAccess(msg.sender)
        returns (string memory)
    {
        return _asset;
    }

    function batchUpdateAccess(
        address[] memory assetViewers,
        bool hasAccess_
    ) external onlyOwner {
        for (uint i = 0; i < assetViewers.length; i++) {
            updateAccess(assetViewers[i], hasAccess_);
        }
    }

    function updateAccess(
        address assetViewer,
        bool hasAccess_
    ) public onlyOwner {
        _hasAccess[assetViewer] = hasAccess_;
    }

    function updateAssetData(
        string memory assetData,
        string memory assetType,
        bool isProcessed
    ) external onlyOwner {
        if (isProcessed) {
            _setAssetData(assetData, assetType);
        } else {
            _processAssetData(assetData, assetType);
        }
    }

    function _setAssetData(
        string memory assetData,
        string memory assetType
    ) internal {
        _asset = assetData;
        _type = assetType;
    }

    function _processAssetData(
        string memory assetData,
        string memory assetType
    ) internal {
        // run data processor
        string memory processedData = assetData;
        _setAssetData(processedData, assetType);
    }

    function _checkAccess(address viewer) internal view returns (bool) {
        return _hasAccess[viewer];
    }
}
