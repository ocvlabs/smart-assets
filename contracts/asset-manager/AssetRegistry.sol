// SPDX-License-Identifier: MIT
// OnChainVision Contracts

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartAsset} from "../smart-asset/SmartAsset.sol";
import {InteractiveAsset} from "../interactive-asset/InteractiveAsset.sol";
import {ITokenFactory} from "./ITokenFactory.sol";

pragma solidity ^0.8.20;

/// @title Register
contract AssetRegistry is Ownable {
    address _tokenFactory;
    mapping(address assetAddress => bool) hasSetup;

    // map all compiled smart assets to used asset
    mapping(address interactiveSmartAssets => mapping(string smartAssets => address assetAddress))
        private _compositions;

    struct AssetData {
        address _creator;
        string _assetType;
        string _assetName;
        uint256 _mintPrice; // @note price in wei
        uint256 _maxSupply;
        uint256 _mintLimit; // @note max mint per wallet
    }

    mapping(address interactiveTokens => AssetData) private _assetData;
    mapping(address interactiveTokens => address) private _creators;
    mapping(address interactiveTokens => uint256) private _mintedSupply;
    mapping(address interactiveTokens => address) private _collectors;
    mapping(address creators => address[]) private _deployments;
    mapping(address collector => mapping(address assetAddress => uint256))
        private _tokenAmountMinted;

    constructor(address controller, address tokenFactory) Ownable(controller) {
        _tokenFactory = tokenFactory;
    }

    modifier onlyCreator(address assetAddress) {
        _isCreator(assetAddress);
        _;
    }

    function _isCreator(address assetAddress) internal view returns (bool) {
        return _creators[assetAddress] == msg.sender || owner() == msg.sender;
    }

    function deployAsset(
        string memory assetName,
        string memory assetType, // @note (e.g., game)
        string memory style,
        string memory body,
        string memory setting,
        string memory script,
        bool isEncoded
    ) public {
        SmartAsset style_ = new SmartAsset(
            address(this),
            msg.sender,
            assetName,
            style,
            "style",
            isEncoded
        );
        SmartAsset body_ = new SmartAsset(
            address(this),
            msg.sender,
            assetName,
            body,
            "body",
            isEncoded
        );
        SmartAsset setting_ = new SmartAsset(
            address(this),
            msg.sender,
            assetName,
            setting,
            "setting",
            isEncoded
        );
        SmartAsset script_ = new SmartAsset(
            address(this),
            msg.sender,
            assetName,
            script,
            "script",
            isEncoded
        );

        // compose smart assets into one interactive asset
        InteractiveAsset newInteractives = new InteractiveAsset(
            assetName,
            msg.sender,
            address(style_),
            address(body_),
            address(setting_),
            address(script_)
        );

        // record interactive asset address to its creator
        _deployments[msg.sender].push(address(newInteractives));
        _creators[address(newInteractives)] = msg.sender;

        // record interactive assets data on mapping
        _assetData[address(newInteractives)]._assetType = assetType;
        _assetData[address(newInteractives)]._assetName = assetName;

        // record smart asset compositions on mapping
        _compositions[address(newInteractives)]["style"] = address(style_);
        _compositions[address(newInteractives)]["body"] = address(body_);
        _compositions[address(newInteractives)]["setting"] = address(setting_);
        _compositions[address(newInteractives)]["script"] = address(script_);
    }

    function setupAsset(
        address assetAddress,
        uint256 mintPrice,
        uint256 maxSupply,
        uint256 mintLimit
    ) public onlyCreator(assetAddress) {
        _assetData[assetAddress]._mintPrice = mintPrice;
        _assetData[assetAddress]._maxSupply = maxSupply;
        _assetData[assetAddress]._mintLimit = mintLimit;
        hasSetup[assetAddress] = true;
    }

    function mintAsset(
        address assetAddress,
        address receiver, // @note user's address where token will be dropped
        uint256 tokenQuantity
    ) public payable returns (uint256[] memory) {
        require(hasSetup[assetAddress], "Asset Not Setup Yet");
        require(tokenQuantity > 0, "Token amount must be greater than zero");
        require(
            _hasSupply(assetAddress, tokenQuantity),
            "Token Quantity will exceed max supply"
        );
        require(
            !_hasMintedMax(receiver, assetAddress, tokenQuantity),
            "Receiver already received max token per wallet"
        );
        require(
            (tokenQuantity * _assetData[assetAddress]._mintPrice) >= msg.value,
            "Receiver already received max token per wallet"
        );

        uint256[] memory newTokenIDs = new uint256[](tokenQuantity);

        for (uint256 i = 0; i < tokenQuantity; i++) {
            // Mint token to factory using assetAddress and receiverAddress
            uint256 tokenId = ITokenFactory(_tokenFactory).mintAsset(
                receiver,
                assetAddress
            );
            newTokenIDs[i] = tokenId;
            _mintedSupply[assetAddress] = tokenId;
            _collectors[assetAddress] = receiver;
            _tokenAmountMinted[receiver][assetAddress] += 1;
        }

        return newTokenIDs;
    }

    function getComposition(
        address assetAddress
    )
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
        return InteractiveAsset(assetAddress).getComposition();
    }

    function addComposition(
        address assetAddress,
        string memory assetType,
        address compositionAddress
    ) public onlyCreator(assetAddress) {
        _compositions[assetAddress][assetType] = compositionAddress;
    }

    function viewComposition(
        address assetAddress,
        string memory assetType
    ) public view returns (address) {
        return _compositions[assetAddress][assetType];
    }

    function _hasMintedMax(
        address userAddress,
        address assetAddress,
        uint256 toMintQuantity
    ) public view returns (bool) {
        uint256 mintedToken = _tokenAmountMinted[userAddress][assetAddress];
        uint256 maxLimit = _assetData[assetAddress]._mintLimit;
        return (mintedToken + toMintQuantity) <= maxLimit;
    }

    function _hasSupply(
        address assetAddress,
        uint256 toMintQuantity
    ) public view returns (bool) {
        uint256 mintedSupply = (_mintedSupply[assetAddress] + 1);
        uint256 maxSupply = _assetData[assetAddress]._maxSupply;
        return (mintedSupply + toMintQuantity) <= maxSupply;
    }

    function recover() public {
        uint amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}
