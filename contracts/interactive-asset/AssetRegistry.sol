// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {SmartAsset} from "../smart-asset/SmartAsset.sol";
import {InteractiveAsset} from "./InteractiveAsset.sol";

/// @title Register
contract AssetRegistry {
    mapping(address assetAddress => bool) hasSetup;

    // map all compiled smart assets to used asset
    mapping(address interactiveSmartAssets => mapping(string smartAssets => address assetAddress))
        private _interactives;

    struct AssetData {
        address _creator;
        string _assetType;
        string _assetName;
        uint256 _mintPrice;
        uint256 _maxSupply;
        uint256 _mintLimit; // @note max mint per wallet
    }

    mapping(address interactives => AssetData) private _assetData;
    mapping(address interactives => address) private _creators;
    mapping(address interactives => address) private _collectors;
    mapping(address creators => address[]) private _deployments;

    mapping(address collector => uint256) private _tokenAmountMinted;

    constructor() {}

    modifier onlyCreator(address assetAddress) {
        _isCreator(assetAddress);
        _;
    }

    function _isCreator(address assetAddress) internal view returns (bool) {
        return _creators[assetAddress] == msg.sender;
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

        // record smart assets on mapping
        _interactives[address(newInteractives)]["style"] = address(style_);
        _interactives[address(newInteractives)]["body"] = address(body_);
        _interactives[address(newInteractives)]["setting"] = address(setting_);
        _interactives[address(newInteractives)]["script"] = address(script_);
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
        address receiverAddress,
        uint256 tokenAmount
    ) public {
        require(hasSetup[assetAddress], "Asset Not Setup Yet");
        // check if tokenAmount is valid
        // check if payment is sufficient

        // mint token to factory using assetAddress and receiverAddress
    }

    function viewComposition(
        address assetAddress
    )
        public
        view
        returns (
            address styleAddress,
            address bodyAddress,
            address settingAddress,
            address scriptAddress
        )
    {
        styleAddress = _interactives[assetAddress]["style"];
        bodyAddress = _interactives[assetAddress]["body"];
        settingAddress = _interactives[assetAddress]["setting"];
        scriptAddress = _interactives[assetAddress]["script"];
    }
}
