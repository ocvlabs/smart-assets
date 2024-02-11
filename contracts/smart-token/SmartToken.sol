// SPDX-License-Identifier: MIT
// OnChainVision Contracts

import {IInteractiveAsset} from "../interactive-asset/IInteractiveAsset.sol";
import {ISmartAsset} from "../smart-asset/ISmartAsset.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity 0.8.20;

contract SmartToken is ERC721, Ownable {
    address public _registry;
    address public _controller;
    address public _assetAddress;
    address public _thumbnailAddress;

    string private _contractURI;
    uint256 _maxSupply;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address registry,
        address controller
    ) ERC721(name, symbol) Ownable(controller) {
        _registry = registry;
        _controller = controller;
        _maxSupply = maxSupply;
    }

    function contractURI() external view returns (string memory) {
        return SmartCodec.encodeJson64(_contractURI);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory image = ISmartAsset(_thumbnailAddress).viewAsset();
        IInteractiveAsset interactives = IInteractiveAsset(_assetAddress);
        (string memory assetName, , , , ) = interactives.getComposition();

        string memory assetName_ = string(
            abi.encodePacked(assetName, " #", Strings.toString(tokenId))
        );

        string memory animation = IInteractiveAsset(_assetAddress).viewAsset();

        return
            SmartCodec.encodeJson64(
                SmartCodec.encodeMetadata(
                    assetName_,
                    "Powered by OnChainVision",
                    image,
                    animation,
                    ""
                )
            );
    }

    function updateController(address newAddress) public {
        require(_controller == msg.sender, "Not authorized");
        _controller = newAddress;
    }

    function updateContractURI(string memory uri) public {
        require(_controller == msg.sender, "Not authorized");
        _contractURI = uri;
    }
}
