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
    address public _imageAddress;
    string public _contractURI;

    uint256 public _tokenId;
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
        _registry = registry;
        _controller = controller;
        _maxSupply = maxSupply;
        _mintPrice = mintPrice;
        _assetAddress = assetAddress;
        _imageAddress = imageAddress;
    }

    function contractURI() external view returns (string memory) {
        return SmartCodec.encodeJson64(_contractURI);
    }

    function mint(address receiver, uint256 qty) public payable returns (bool) {
        require(receiver != address(0), "Zero address not allowed");
        require(msg.value >= _mintPrice * qty, "Payment not enough");
        require((qty + _tokenId) < _maxSupply, "Maximum supply reached");
        address assetCreator = IInteractiveAsset(_assetAddress).viewCreator();
        address imageCreator = ISmartAsset(_imageAddress).viewCreator();

        // calculate 5% royalties
        uint256 royalties = (msg.value * 5) / 100;
        // send royalties to creators & service fees
        (bool delivered1, ) = payable(assetCreator).call{value: royalties}("");
        (bool delivered2, ) = payable(imageCreator).call{value: royalties}("");
        (bool delivered3, ) = payable(_controller).call{value: royalties}("");
        require(delivered1 && delivered2 && delivered3, "Royalties sent");
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(receiver, _tokenId);
            emit TokenMinted(receiver, _tokenId);
            _tokenId++;
        }
        return true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory image = ISmartAsset(_imageAddress).viewAsset();
        IInteractiveAsset interactives = IInteractiveAsset(_assetAddress);
        (string memory assetName, , , , ) = interactives.getComposition();

        string memory name = string(
            abi.encodePacked(assetName, " #", Strings.toString(tokenId))
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

    function updateAssetAddress(address newAddress) public onlyOwner {
        _assetAddress = newAddress;
    }

    function updateImageAddress(address newAddress) public onlyOwner {
        _imageAddress = newAddress;
    }

    function updateContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function recover() public {
        uint256 amountToRecover = address(this).balance;
        require(amountToRecover > 0, "Nothing to recover");
        (bool recovered, ) = owner().call{value: amountToRecover}("");
        require(recovered, "Failed to recover ether");
    }

    function remove() public payable {
        require(_controller == msg.sender, "Not authorized");
        address payable addr = payable(address(_controller));
        selfdestruct(addr);
    }
}
