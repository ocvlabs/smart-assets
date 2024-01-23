// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SmartAsset} from "../smart-asset/SmartAsset.sol";
import {InteractiveAsset} from "../interactive-asset/InteractiveAsset.sol";

/// @title Deploy Asset Data as Smart Contracts
contract AssetDeployer is Ownable {
    uint256 _inscribeFee;
    uint256 _deployFee;

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

    constructor(address controller) Ownable(controller) {
        _inscribeFee = 0;
        _deployFee = 0;
    }

    modifier onlyDeployer(address assetAddress) {
        _isDeployer(assetAddress);
        _;
    }

    function _isDeployer(address assetAddress) internal view returns (bool) {
        return _deployers[assetAddress] == msg.sender || owner() == msg.sender;
    }

    function setServiceFees(
        uint256 inscribeFee,
        uint256 deployFee
    ) public payable onlyOwner {
        _inscribeFee = inscribeFee;
        _deployFee = deployFee;
    }

    function inscribeSmartAsset(
        address assetAddress,
        string memory assetData,
        string memory assetType,
        bool isEncoded
    ) public payable onlyDeployer(assetAddress) {
        require(msg.value >= _inscribeFee, "Payment not enough");
        // deploy smart asset
        address newAsset = deploySmartAsset(assetData, assetType, isEncoded);
        // record smart asset compositions
        _compositions[assetAddress][assetType] = address(newAsset);
    }

    function deploySmartAsset(
        string memory assetData,
        string memory assetType,
        bool isEncoded
    ) public payable returns (address assetAddress) {
        SmartAsset newAsset = new SmartAsset(
            address(this),
            msg.sender,
            "Smart Asset",
            assetData,
            assetType,
            isEncoded
        );
        _deployments[msg.sender].push(address(newAsset));
        _deployers[address(newAsset)] = msg.sender;

        assetAddress = address(newAsset);
    }

    function deployInteractiveAsset(
        string memory assetName,
        string memory assetType, // @note (e.g., game)
        string memory style,
        string memory body,
        string memory setting,
        string memory script,
        bool isEncoded
    ) public payable {
        require(msg.value >= _deployFee, "Payment not enough");
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

    function getDeployments(
        address creatorAddress
    ) public view returns (address[] memory) {
        return _deployments[creatorAddress];
    }

    function getDeploymentsByIndex(
        address creatorAddress,
        uint256 index
    ) public view returns (address) {
        return _deployments[creatorAddress][index];
    }

    function recover() public {
        uint amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}
