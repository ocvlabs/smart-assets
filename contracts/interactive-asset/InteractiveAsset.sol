// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IInteractiveAsset.sol";

/// @title Compose smart assets into interactive 'markup-based' smart asset
contract InteractiveAsset {
    address private _creatorAddress;
    address private _styleAddress;
    address private _bodyAddress;
    address private _settingAddress;
    address private _scriptAddress;

    constructor(
        address creatorAddress,
        address styleAddress,
        address bodyAddress,
        address settingAddress,
        address scriptAddress
    ) {
        _creatorAddress = creatorAddress;
        _styleAddress = styleAddress;
        _bodyAddress = bodyAddress;
        _settingAddress = settingAddress;
        _scriptAddress = scriptAddress;
    }

    function viewComposition()
        public
        view
        returns (
            address styleAddress,
            address bodyAddress,
            address settingAddress,
            address scriptAddress
        )
    {
        styleAddress = _styleAddress;
        bodyAddress = _bodyAddress;
        settingAddress = _settingAddress;
        scriptAddress = _scriptAddress;
    }
}
