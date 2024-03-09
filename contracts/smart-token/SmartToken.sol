// SPDX-License-Identifier: MIT
// OnChainVision Contracts

import {IInteractiveAsset} from "../interactive-asset/IInteractiveAsset.sol";
import {ISmartAsset} from "../smart-asset/ISmartAsset.sol";
import {SmartCodec} from "../smart-codec/SmartCodec.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "./Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity 0.8.19;

contract SmartToken is ERC721, Ownable {
    address public _registry;
    address public _controller;
    address public _assetAddress;
    address public _imageAddress;
    string public _contractURI;
    string public _tokenName;

    uint256 public _tokenId = 0;
    uint256 public _maxSupply;
    uint256 public _mintPrice;

    event TokenMinted(address indexed to, uint256 tokenId);

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 mintPrice,
        address registry,
        address controller,
        address assetAddress,
        address imageAddress
    ) ERC721(name, symbol) Ownable(controller) {
        _tokenName = name;
        _registry = registry;
        _controller = controller;
        _maxSupply = maxSupply;
        _mintPrice = mintPrice;
        _assetAddress = assetAddress;
        _imageAddress = imageAddress;

        // mint token zero
        _safeMint(controller, _tokenId);
    }

    function contractURI() external view returns (string memory) {
        return SmartCodec.encodeJson64(_contractURI);
    }

    function mint(
        address receiver,
        uint256 qty
    ) external payable returns (bool) {
        require(receiver != address(0), "Zero address not allowed");
        require(msg.value >= _mintPrice * qty, "Payment not enough");
        require((qty + _tokenId) < _maxSupply, "Maximum supply reached");

        // retrieve asset creator addresses
        address assetCreator = IInteractiveAsset(_assetAddress).viewCreator();
        address imageCreator = ISmartAsset(_imageAddress).viewCreator();

        // calculate 5% royalties
        uint256 royalties = (msg.value * 5) / 100;

        // send royalties to creators & service fees
        (bool delivered1, ) = payable(assetCreator).call{value: royalties}("");
        (bool delivered2, ) = payable(imageCreator).call{value: royalties}("");
        (bool delivered3, ) = payable(_controller).call{value: royalties}("");
        (bool delivered4, ) = payable(owner()).call{
            value: address(this).balance
        }("");

        require(
            delivered1 && delivered2 && delivered3 && delivered4,
            "Royalties and payment sent"
        );

        // mint tokens
        for (uint256 i = 0; i < qty; i++) {
            _tokenId++;
            _safeMint(receiver, _tokenId);
            emit TokenMinted(receiver, _tokenId);
        }

        return true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory image = ISmartAsset(_imageAddress).viewAsset();
        string memory name = string(
            abi.encodePacked(_tokenName, " #", Strings.toString(tokenId))
        );
        string memory animation = IInteractiveAsset(_assetAddress).viewAsset();

        return
            SmartCodec.encodeJson64(
                SmartCodec.encodeMetadata(
                    name,
                    "Powered by OnChainVision",
                    image,
                    animation,
                    ""
                )
            );
    }

    function updateAssetAddress(address newAddress) external onlyOwner {
        _assetAddress = newAddress;
    }

    function updateImageAddress(address newAddress) external onlyOwner {
        _imageAddress = newAddress;
    }

    function updateContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function recover() external {
        (bool recovered, ) = payable(_controller).call{
            value: address(this).balance
        }("");
        require(recovered, "Failed to recover ether");
    }
}
