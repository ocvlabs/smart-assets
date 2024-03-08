// SPDX-License-Identifier: MIT

import {ERC20Recoverable} from "../smart-token/ERC20Recoverable.sol";
import {IMembership} from "../smart-pricer/IMembership.sol";
import {SmartAsset, ISmartAsset} from "../smart-assets/contracts/smart-asset/SmartAsset.sol";
import {InteractiveAsset, IInteractiveAsset} from "../smart-assets/contracts/interactive-asset/InteractiveAsset.sol";

pragma solidity ^0.8.20;

/// @title Asset Builder and Deployer for Smart Assets
/// @author raldblox | rald@ocvlabs.com
contract AssetBuilder is ERC20Recoverable {
    address payable private admin;
    address payable private treasury;

    uint256 public _interactiveAssetCounter;
    uint256 public _smartAssetCounter;
    uint256 public _customAssetCounter;

    address private _currentDeployer;
    bool private _isDeploying = false;

    uint256 public deploymentFees = 0 ether;
    uint256 public customFees = 0 ether;

    IMembership public membership;
    bool subscriptionEnabled = false;
    mapping(address subscriber => uint256) public _discounts;

    constructor() {
        admin = payable(msg.sender);
        treasury = payable(msg.sender);
    }

    struct AssetProps {
        address deployer;
        uint256 timeDeployed;
    }

    mapping(address asset => AssetProps) _properties;

    mapping(address deployer => address[] asset) public _interactives;
    mapping(address deployer => address[] asset) public _smartAssets;
    mapping(address deployer => address[] asset) public _customAssets;
    mapping(address asset => mapping(string assetType => address smartAsset))
        public _compositions;

    event NewSmartAsset(address asset, address deployer);
    event NewCustomAsset(address asset, address deployer);
    event NewInteractiveAsset(address asset, address deployer);

    modifier onlyAdmin() {
        require(admin == msg.sender, "Unauthorized");
        _;
    }

    function deploy(
        string memory name,
        string memory markup,
        string memory style,
        string memory setting,
        string memory script,
        bool isEncoded
    ) public payable returns (address) {
        require(!_isDeploying, "Please wait the current deployment to finish");
        if (subscriptionEnabled) {
            (, uint256 discount) = IMembership(membership).viewMembership(
                msg.sender
            );
            uint256 discountedPrice = (deploymentFees * (100 - discount)) / 100;
            require(
                msg.value >= discountedPrice,
                "Custom asset creation fees not enough"
            );
            uint256 discountSaved = deploymentFees - discountedPrice;
            _discounts[msg.sender] += discountSaved;
        } else {
            require(
                msg.value >= deploymentFees,
                "Custom asset creation fees not enough"
            );
        }

        _isDeploying = true;
        _currentDeployer = msg.sender;

        // build interactives
        address interactiveAsset = build(
            name,
            markup,
            style,
            setting,
            script,
            isEncoded
        );

        _properties[interactiveAsset].timeDeployed = block.timestamp;

        _isDeploying = false;
        _currentDeployer = address(0);

        return interactiveAsset;
    }

    function enableSubscription(address planAddress) public onlyAdmin {
        require(
            IMembership(planAddress).enabled(),
            "Membership plan not enabled"
        );
        membership = IMembership(planAddress);
        subscriptionEnabled = true;
    }

    function toggleSubscription(bool enabled) public onlyAdmin {
        require(subscriptionEnabled != enabled, "Already set");
        subscriptionEnabled = enabled;
    }

    function build(
        string memory name,
        string memory markup,
        string memory style,
        string memory setting,
        string memory script,
        bool isEncoded
    ) internal returns (address) {
        // deploy smart assets
        address _style = create(name, style, "style", isEncoded);
        address _markup = create(name, markup, "markup", isEncoded);
        address _setting = create(name, setting, "setting", isEncoded);
        address _script = create(name, script, "script", isEncoded);

        // compile into interactives
        address asset = compile(name, _style, _markup, _setting, _script);
        return asset;
    }

    function create(
        string memory assetName,
        string memory assetData,
        string memory assetType,
        bool isEncoded
    ) public payable returns (address) {
        // checks if it's coming from deployment
        if (!_isDeploying) {
            if (subscriptionEnabled) {
                (, uint256 discount) = IMembership(membership).viewMembership(
                    msg.sender
                );
                uint256 discountedPrice = (customFees * (100 - discount)) / 100;
                require(
                    msg.value >= discountedPrice,
                    "Custom asset creation fees not enough"
                );
                uint256 discountSaved = customFees - discountedPrice;
                _discounts[msg.sender] += discountSaved;
            } else {
                require(
                    msg.value >= customFees,
                    "Custom asset creation fees not enough"
                );
            }
        }

        SmartAsset newSmartAsset = new SmartAsset(
            address(this),
            msg.sender,
            assetName,
            assetData,
            assetType,
            isEncoded
        );

        if (_isDeploying) {
            require(
                _currentDeployer == msg.sender,
                "Caller not the current deployer"
            );
            emit NewSmartAsset(address(newSmartAsset), msg.sender);
            _smartAssets[msg.sender].push(address(newSmartAsset));
            _smartAssetCounter++;
        } else {
            emit NewCustomAsset(address(newSmartAsset), msg.sender);
            _customAssets[msg.sender].push(address(newSmartAsset));
            _customAssetCounter++;
        }

        return address(newSmartAsset);
    }

    function compile(
        string memory assetName,
        address style,
        address markup,
        address setting,
        address script
    ) internal returns (address) {
        InteractiveAsset newInteractiveAsset = new InteractiveAsset(
            assetName,
            msg.sender,
            style,
            markup,
            setting,
            script
        );

        emit NewInteractiveAsset(address(newInteractiveAsset), msg.sender);

        _compositions[address(newInteractiveAsset)]["style"] = style;
        _compositions[address(newInteractiveAsset)]["markup"] = markup;
        _compositions[address(newInteractiveAsset)]["setting"] = setting;
        _compositions[address(newInteractiveAsset)]["script"] = script;
        _interactives[msg.sender].push(address(newInteractiveAsset));
        _interactiveAssetCounter++;

        return address(newInteractiveAsset);
    }

    function countDeployments(
        address deployer
    )
        public
        view
        returns (uint256 interactives, uint256 smart, uint256 custom)
    {
        interactives = _interactives[deployer].length;
        smart = _smartAssets[deployer].length;
        custom = _customAssets[deployer].length;
    }

    function viewAssetByAddress(
        address asset,
        bool isInteractive
    ) external view returns (string memory) {
        require(asset != address(0), "");
        if (isInteractive) {
            return IInteractiveAsset(asset).viewAsset();
        } else {
            return ISmartAsset(asset).viewAsset();
        }
    }

    function updateTreasury(address newTreasury) external {
        require(treasury == msg.sender, "Unauthorized");
        require(newTreasury != treasury, "Must be new treasury");
        treasury = payable(newTreasury);
    }
}
