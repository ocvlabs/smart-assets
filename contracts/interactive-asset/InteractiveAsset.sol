// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IInteractiveAsset.sol";

/// @title Compose smart assets into interactive 'markup-based' smart asset
contract InteractiveAsset is IInteractiveAsset {
    string _assetName;
    address private _creatorAddress;
    address private _styleAddress;
    address private _bodyAddress;
    address private _settingAddress;
    address private _scriptAddress;

    constructor(
        string memory assetName,
        address creatorAddress,
        address styleAddress,
        address bodyAddress,
        address settingAddress,
        address scriptAddress
    ) {
        _assetName = assetName;
        _creatorAddress = creatorAddress;
        _styleAddress = styleAddress;
        _bodyAddress = bodyAddress;
        _settingAddress = settingAddress;
        _scriptAddress = scriptAddress;
    }

    function getComposition()
        public
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
}
