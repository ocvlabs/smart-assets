// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

import {ISmartAsset} from "./ISmartAsset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";

abstract contract PermissionedSmartAsset is ISmartAsset, Ownable {
    string private _name;
    string private _data;
    string private _type;

    bool _isPublic = false;

    address public _registry;

    error NoAccess(address viewer);
    event AssetUpdated(address owner);

    mapping(address assetViewer => bool) private _hasAccess;

    constructor(
        address registry,
        address creator,
        string memory assetName,
        string memory assetData,
        string memory assetType,
        bool isEncoded
    ) Ownable(creator) {
        if (isEncoded) {
            _setAssetData(assetName, assetData, assetType);
        } else {
            _processAssetData(assetName, assetData, assetType);
        }
        updateAccess(registry, true);
        updateAccess(creator, true);
        _registry = registry;
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

    function updateVisibility(bool isPublic) public onlyOwner {
        _isPublic = isPublic;
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
        bool isEncoded
    ) external onlyOwner {
        if (isEncoded) {
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
        emit AssetUpdated(msg.sender);
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
        if (_isPublic) {
            return true;
        } else {
            if (_hasAccess[viewer]) {
                return true;
            } else {
                revert NoAccess(msg.sender);
            }
        }
    }
}
