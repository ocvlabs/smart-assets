// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./IInteractiveAsset.sol";
import "../smart-asset/ISmartAsset.sol";
import "../smart-codec/SmartCodec.sol";

/// @title Compose smart assets into interactive 'markup-based' smart asset
contract InteractiveAsset is IInteractiveAsset, Ownable {
    string _assetName;
    address private _creatorAddress;
    address private _styleAddress;
    address private _bodyAddress;
    address private _settingAddress;
    address private _scriptAddress;

    constructor(
        string memory name,
        address creator,
        address style,
        address body,
        address setting,
        address script
    ) Ownable(creator) {
        _assetName = name;
        _creatorAddress = creator;
        _styleAddress = style;
        _bodyAddress = body;
        _settingAddress = setting;
        _scriptAddress = script;
    }

    function getComposition()
        external
        view
        returns (
            string memory assetName,
            address styleAddress,
            address bodyAddress,
            address settingAddress,
            address scriptAddress
        )
    {
        assetName = _assetName;
        styleAddress = _styleAddress;
        bodyAddress = _bodyAddress;
        settingAddress = _settingAddress;
        scriptAddress = _scriptAddress;
    }

    function viewAsset() external view returns (string memory) {
        string memory style = ISmartAsset(_styleAddress).viewAsset();
        string memory body = ISmartAsset(_bodyAddress).viewAsset();
        string memory setting = ISmartAsset(_settingAddress).viewAsset();
        string memory script = ISmartAsset(_scriptAddress).viewAsset();

        string memory markup = SmartCodec.encodeMarkup64(
            _assetName,
            style,
            body,
            setting,
            script
        );

        return markup;
    }

    function viewCreator() external view returns (address) {
        return _creatorAddress;
    }
}
