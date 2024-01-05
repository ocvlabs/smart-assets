// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

import {ISmartAsset} from "./ISmartAsset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";

contract SmartAsset is ISmartAsset, Ownable {
    string private _name;
    string private _data;
    string private _type;

    address public _registry;

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
        _registry = registry;
    }

    function getAssetData()
        external
        view
        returns (
            string memory assetName,
            string memory assetData,
            string memory assetType,
            address assetCreator
        )
    {
        return (viewName(), viewAsset(), viewType(), owner());
    }

    function viewAsset() public view returns (string memory) {
        string memory asset_ = SmartCodec.decode64(_data);
        return asset_;
    }

    function viewType() public view returns (string memory) {
        return _type;
    }

    function viewName() public view returns (string memory) {
        return _name;
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
}
