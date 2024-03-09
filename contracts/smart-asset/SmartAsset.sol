// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";
import {ISmartAsset} from "./ISmartAsset.sol";

contract SmartAsset is ISmartAsset, Ownable {
    address public _registry;
    address public _creator;

    string private _name;
    string private _data;
    string private _type;

    event AssetUpdated(address owner);

    constructor(
        address registry,
        address creator,
        string memory assetName,
        string memory assetData,
        string memory assetType,
        bool isEncoded
    ) Ownable(creator) {
        _registry = registry;
        _creator = creator;
        if (isEncoded) {
            _setup(assetName, assetData, assetType);
        } else {
            _process(assetName, assetData, assetType);
        }
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
        string memory asset = SmartCodec.decode64(_data);
        return asset;
    }

    function viewType() public view returns (string memory) {
        return _type;
    }

    function viewName() public view returns (string memory) {
        return _name;
    }

    function viewRegistry() external view returns (address) {
        return _registry;
    }

    function viewCreator() external view returns (address) {
        return _creator;
    }

    function update(
        string memory assetName,
        string memory assetData,
        string memory assetType,
        bool isEncoded
    ) external onlyOwner {
        if (isEncoded) {
            _setup(assetName, assetData, assetType);
        } else {
            _process(assetName, assetData, assetType);
        }
    }

    function _setup(
        string memory assetName,
        string memory assetData,
        string memory assetType
    ) internal {
        _name = assetName;
        _data = assetData;
        _type = assetType;
        emit AssetUpdated(msg.sender);
    }

    function _process(
        string memory assetName,
        string memory assetData,
        string memory assetType
    ) internal {
        string memory processedData = SmartCodec.encode64(assetData);
        _setup(assetName, processedData, assetType);
    }
}
