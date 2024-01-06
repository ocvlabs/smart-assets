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
contract TokenFactory is
    ERC721("Interactive NFT", "iNFT"),
    Ownable(msg.sender),
    ITokenFactory
{
    uint256 tokenIds;
    mapping(uint256 tokenId => address) _assetAddresses;

    function mintAsset(
        address receiver,
        address assetAddress
    ) public override returns (uint256) {
        uint256 newTokenID = tokenIds;
        _linkAsset(newTokenID, assetAddress);
        _safeMint(receiver, tokenIds);
        tokenIds++;
        return newTokenID;
    }

    function contractURI() external pure returns (string memory) {
        return SmartCodec.encodeJson64("");
    }

    function tokenURI(
        uint256 assetId
    ) public view override returns (string memory) {
        address assetAddress = _assetAddresses[assetId];

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
                    assetName,
                    "Powered by OCVLabs",
                    thumbnail,
                    markup,
                    attributes
                )
            );
    }

    function _linkAsset(uint256 tokenId, address assetAddress) internal {
        _assetAddresses[tokenId] = assetAddress;
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

    function recover() public {
        uint amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}
