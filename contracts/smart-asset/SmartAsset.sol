// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

import {ISmartAsset} from "./ISmartAsset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";

abstract contract SmartAsset is ISmartAsset, Ownable {
    string private _name;
    string private _data;
    string private _type;

    bool isPublic = false;

    mapping(address assetViewer => bool) private _hasAccess;

    constructor(
        string memory assetName,
        string memory assetData,
        string memory assetType,
        bool isProcessed
    ) {
        if (isProcessed) {
            _setAssetData(assetName, assetData, assetType);
        } else {
            _processAssetData(assetName, assetData, assetType);
        }
        updateAccess(msg.sender, true);
    }

    modifier hasAccess(address assetViewer) {
        _checkAccess(assetViewer);
        _;
    }

    function getAsset()
        external
        view
        hasAccess(msg.sender)
        returns (
            string memory assetName,
            string memory assetData,
            string memory assetType,
            address assetCreator
        )
    {
        return (viewName(), viewAsset(), viewType(), owner());
    }

    function viewAsset()
        public
        view
        hasAccess(msg.sender)
        returns (string memory)
    {
        string memory asset_ = SmartCodec.decode64(_data);
        return (asset_);
    }

    function viewType()
        public
        view
        hasAccess(msg.sender)
        returns (string memory)
    {
        return _type;
    }

    function viewName() public view returns (string memory) {
        return _name;
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
        string memory assetName,
        string memory assetData,
        string memory assetType,
        bool isProcessed
    ) external onlyOwner {
        if (isProcessed) {
            _setAssetData(assetName, assetData, assetType);
        } else {
            _processAssetData(assetName, assetData, assetType);
        }
    }

    function _setAssetData(
        string memory assetName,
        string memory assetData,
        string memory assetType
    ) internal {
        _name = assetName;
        _data = assetData;
        _type = assetType;
    }

    function _processAssetData(
        string memory assetName,
        string memory assetData,
        string memory assetType
    ) internal {
        string memory processedData = SmartCodec.encode64(assetData);
        _setAssetData(assetName, processedData, assetType);
    }

    function _checkAccess(address viewer) internal view returns (bool) {
        if (isPublic) {
            return true;
        } else {
            return _hasAccess[viewer];
        }
    }
}
