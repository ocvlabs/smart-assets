// SPDX-License-Identifier: MIT

import {Ownable} from "../smart-token/Ownable.sol";
import {IMembership} from "../smart-pricer/IMembership.sol";
import {ERC20Recoverable} from "../smart-token/ERC20Recoverable.sol";
import {SmartAsset, ISmartAsset} from "../smart-asset/SmartAsset.sol";
import {InteractiveAsset, IInteractiveAsset} from "../interactive-asset/InteractiveAsset.sol";

pragma solidity ^0.8.19;

/// @title Asset Builder for Interactives & Smart Assets
/// @author raldblox | rald@ocvlabs.com
/// @dev Deploy each component as smart-asset
/// and compiled to form interactive-asset
contract AssetBuilder is Ownable(msg.sender) {
    uint256 public _interactiveAssetCounter;
    uint256 public _smartAssetCounter;
    uint256 public _customAssetCounter;

    address private currentDeployer;
    bool private deployingInteractives = false;
    uint256 public customFees;

    IMembership public membershipPlan;
    uint256 deploymentPrice;
    bool subscriptionEnabled = false;
    mapping(address subscriber => uint256) public _discounts;

    constructor() {
        deploymentPrice = 0 ether;
    }

    struct AssetProps {
        string title;
        address deployer;
        uint256 timeDeployed;
    }

    mapping(address asset => AssetProps) public properties;

    mapping(address deployer => address[] asset) public interactives;
    mapping(address deployer => address[] asset) public smartAssets;
    mapping(address deployer => address[] asset) public customAssets;

    mapping(address asset => mapping(string assetType => address smartAsset))
        public compositions;

    event NewSmartAsset(address asset, address deployer);
    event NewCustomAsset(address asset, address deployer);
    event NewInteractiveAsset(address asset, address deployer);

    function deploy(
        string memory name,
        string memory markup,
        string memory style,
        string memory setting,
        string memory script,
        bool isEncoded
    ) public payable returns (address) {
        require(
            !deployingInteractives,
            "Please wait for the current deployment to finish"
        );

        if (subscriptionEnabled) {
            (, uint256 discount) = membershipPlan.viewMembership(msg.sender);
            uint256 discountedPrice = (deploymentPrice * (100 - discount)) /
                100;
            require(
                msg.value >= discountedPrice,
                "Custom asset creation fees not enough"
            );
            uint256 discountSaved = deploymentPrice - discountedPrice;
            _discounts[msg.sender] += discountSaved;
        } else {
            require(
                msg.value >= deploymentPrice,
                "Custom asset creation fees not enough"
            );
        }

        deployingInteractives = true;
        currentDeployer = msg.sender;

        // build interactives
        address interactiveAsset = build(
            name,
            markup,
            style,
            setting,
            script,
            isEncoded
        );

        properties[interactiveAsset].timeDeployed = block.timestamp;
        properties[interactiveAsset].title = name;

        deployingInteractives = false;
        currentDeployer = address(0);

        return interactiveAsset;
    }

    function updateSubscription(
        IMembership planAddress,
        bool enabled
    ) external onlyOwner {
        require(subscriptionEnabled != enabled, "Already set");
        membershipPlan = planAddress;
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
        SmartAsset newSmartAsset = new SmartAsset(
            address(this),
            msg.sender,
            assetName,
            assetData,
            assetType,
            isEncoded
        );

        if (deployingInteractives) {
            require(
                currentDeployer == msg.sender,
                "Caller not the current deployer"
            );
            emit NewSmartAsset(address(newSmartAsset), msg.sender);
            smartAssets[msg.sender].push(address(newSmartAsset));
            _smartAssetCounter++;
        } else {
            emit NewCustomAsset(address(newSmartAsset), msg.sender);
            customAssets[msg.sender].push(address(newSmartAsset));
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

        compositions[address(newInteractiveAsset)]["style"] = style;
        compositions[address(newInteractiveAsset)]["markup"] = markup;
        compositions[address(newInteractiveAsset)]["setting"] = setting;
        compositions[address(newInteractiveAsset)]["script"] = script;
        interactives[msg.sender].push(address(newInteractiveAsset));
        _interactiveAssetCounter++;

        return address(newInteractiveAsset);
    }

    function countDeployments(
        address deployer
    )
        public
        view
        returns (uint256 _interactives, uint256 _smart, uint256 _custom)
    {
        _interactives = interactives[deployer].length;
        _smart = smartAssets[deployer].length;
        _custom = customAssets[deployer].length;
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

    function updatePrice(uint256 price) external onlyOwner {
        deploymentPrice = price;
    }

    function recover() public {
        (bool recovered, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(recovered, "Failed to recover ether");
    }
}
