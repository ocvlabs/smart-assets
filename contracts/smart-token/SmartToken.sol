// SPDX-License-Identifier: MIT
// OnChainVision Contracts

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";
import {ISmartAsset} from "../interfaces/ISmartAsset.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IInteractiveAsset} from "../interfaces/IInteractiveAsset.sol";

pragma solidity ^0.8.19;

/// @title Collection of Interactive Assets
contract SmartToken is ERC721 {
    address public _assetAddress;

    constructor(
        string memory name,
        string memory symbol,
        address assetAddress
    ) ERC721(name, symbol) {
        _assetAddress = assetAddress;
    }

    function contractURI() external pure returns (string memory) {
        return SmartCodec.encodeJson64("");
    }

    function tokenURI(
        uint256 assetId
    ) public view override returns (string memory) {
        address assetAddress = _assetAddress;

        // Create an instance of ISmartAsset with the contract address
        IInteractiveAsset interactives = IInteractiveAsset(assetAddress);

        string memory thumbnail = "";
        string memory attributes = "";

        (
            string memory assetName,
            address styleAddress,
            address bodyAddress,
            address settingAddress,
            address scriptAddress
        ) = interactives.getComposition();

        string memory assetName_ = string(
            abi.encodePacked(assetName, "#", assetId)
        );

        // load all asset data

        string memory markup = _generateMarkup(
            assetName,
            styleAddress,
            bodyAddress,
            settingAddress,
            scriptAddress
        );

        return
            SmartCodec.encodeJson64(
                SmartCodec.encodeMetadata(
                    assetName_,
                    "Powered by OCVLabs",
                    thumbnail,
                    markup,
                    attributes
                )
            );
    }

    function _generateMarkup(
        string memory assetName,
        address styleAddress,
        address bodyAddress,
        address settingAddress,
        address scriptAddress
    ) internal view returns (string memory) {
        string memory style = ISmartAsset(styleAddress).viewAsset();
        string memory body = ISmartAsset(bodyAddress).viewAsset();
        string memory setting = ISmartAsset(settingAddress).viewAsset();
        string memory script = ISmartAsset(scriptAddress).viewAsset();

        string memory markup = SmartCodec.encodeMarkup64(
            assetName,
            style,
            body,
            setting,
            script
        );

        return markup;
    }
}
