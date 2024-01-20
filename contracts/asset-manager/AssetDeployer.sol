// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartAsset} from "../smart-asset/SmartAsset.sol";
import {InteractiveAsset} from "../interactive-asset/InteractiveAsset.sol";

/// @title Deploy Asset Data as Smart Contracts
contract AssetDeployer is Ownable {
    mapping(address assetAddress => bool) hasSetup;

    struct AssetData {
        string _assetType;
        string _assetName;
    }

    mapping(address interactiveTokens => AssetData) private _assetData;
    mapping(address interactiveTokens => address) private _deployers;
    mapping(address creators => address[]) private _deployments;
    mapping(address interactiveSmartAssets => mapping(string smartAssets => address assetAddress))
        private _compositions;

    constructor(address controller) Ownable(controller) {}

    modifier onlyDeployer(address assetAddress) {
        _isDeployer(assetAddress);
        _;
    }

    function _isDeployer(address assetAddress) internal view returns (bool) {
        return _deployers[assetAddress] == msg.sender || owner() == msg.sender;
    }

    function deployAsset(
        string memory assetName,
        string memory assetType, // @note (e.g., game)
        string memory style,
        string memory body,
        string memory setting,
        string memory script,
        bool isEncoded
    ) public payable {
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
        _deployers[address(newInteractives)] = msg.sender;

        // record interactive assets data on mapping
        _assetData[address(newInteractives)]._assetType = assetType;
        _assetData[address(newInteractives)]._assetName = assetName;

        // record smart asset compositions on mapping
        _compositions[address(newInteractives)]["style"] = address(style_);
        _compositions[address(newInteractives)]["body"] = address(body_);
        _compositions[address(newInteractives)]["setting"] = address(setting_);
        _compositions[address(newInteractives)]["script"] = address(script_);
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

    function updateComposition(
        address assetAddress,
        string memory assetType,
        address compositionAddress
    ) public onlyDeployer(assetAddress) {
        _compositions[assetAddress][assetType] = compositionAddress;
    }

    function viewComposition(
        address assetAddress,
        string memory assetType
    ) public view returns (address) {
        return _compositions[assetAddress][assetType];
    }

    function recover() public {
        uint amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}
