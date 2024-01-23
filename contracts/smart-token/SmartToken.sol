// SPDX-License-Identifier: MIT
// OnChainVision Contracts

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";
import {ISmartAsset} from "../interfaces/ISmartAsset.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {IInteractiveAsset} from "../interfaces/IInteractiveAsset.sol";

pragma solidity ^0.8.19;

/// @title Collection of Interactive Assets
contract SmartToken is ERC721 {
    address private _controller;
    address public _assetAddress;
    address public _thumbnailAddress;

    constructor(
        string memory name,
        string memory symbol,
        address assetAddress,
        address controller
    ) ERC721(name, symbol) {
        _assetAddress = assetAddress;
        _controller = controller;
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

        // retrieve thumbnail
        string memory thumbnail_ = ISmartAsset(_thumbnailAddress).viewAsset();
        string memory thumbnail = SmartCodec.encodeSvg64(thumbnail_);
        string memory attributes = "";

        (
            string memory assetName,
            address styleAddress,
            address bodyAddress,
            address settingAddress,
            address scriptAddress
        ) = interactives.getComposition();

        string memory assetName_ = string(
            abi.encodePacked(assetName, " #", Strings.toString(assetId))
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
                    "Powered by OnChainVision",
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

    function updateThumbnail(address thumbnailAddress) public {
        require(_controller == msg.sender, "Not authorized");
        _thumbnailAddress = thumbnailAddress;
    }

    function updateController(address newAddress) public {
        require(_controller == msg.sender, "Not authorized");
        _controller = newAddress;
    }
}
