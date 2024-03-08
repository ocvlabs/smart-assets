// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IMembership} from "./IMembership.sol";

contract ProPlan is IMembership {
    address payable private treasury;

    uint256 public _membershipFee; // @note monthly payment
    uint256 public _membershipDiscount;
    mapping(address => uint) _subscriptionTime;
    mapping(address => bool) _subscribers;

    // Non-Expiry Plan Subscription
    uint256 public _nonExpiryPlanFee;
    uint256 public _nonExpiryDiscount;
    bool public _nonExpiryPlanEnabled;
    mapping(address => bool) _hasNonExpiryPlan;

    constructor() {
        treasury = payable(msg.sender);
    }

    modifier onlyTreasury() {
        require(treasury == msg.sender, "Unauthorized");
        _;
    }

    modifier noActiveSubscription(address user) {
        if (_subscribers[user]) {
            bool isActive = checkExpiry(user) >= block.timestamp;
            require(!isActive, "Already subscribed");
        }
        _;
    }

    function subscribe(
        address user
    ) external payable noActiveSubscription(user) {
        require(msg.value >= _membershipFee, "Payment not enough");
        _subscriptionTime[user] = block.timestamp;
        _subscribers[user] = true;
    }

    function setPrice(uint256 priceInWei) public onlyTreasury {
        require(priceInWei > 0, "Pricing must not be free");
        _membershipFee = priceInWei;
    }

    function setDiscount(uint256 percentDiscount) public onlyTreasury {
        require(
            percentDiscount <= 100,
            "Must not exceed to 100% _membershipDiscount"
        );
        _membershipDiscount = percentDiscount;
    }

    function enableNonExpiryPlan(
        bool activate,
        uint256 nonExpiryPlanFee,
        uint256 nonExpiryDiscount
    ) external onlyTreasury {
        require(_nonExpiryPlanEnabled != activate, "Already set");
        _nonExpiryPlanEnabled = activate;
        _nonExpiryPlanFee = nonExpiryPlanFee;
        _nonExpiryDiscount = nonExpiryDiscount;
    }

    function subscribeToNonExpiryPlan(
        address user,
        bool toSubscribe
    ) public payable {
        require(_hasNonExpiryPlan[user] != toSubscribe, "Already set");
        if (msg.sender == treasury) {
            _hasNonExpiryPlan[user] = toSubscribe;
        } else {
            if (_nonExpiryPlanEnabled) {
                require(msg.value >= _nonExpiryPlanFee, "Payment not enough");
                _hasNonExpiryPlan[user] = toSubscribe;
            }
        }
    }

    function viewMembership(address user) public view returns (bool, uint256) {
        if (_hasNonExpiryPlan[user]) {
            return (true, _nonExpiryDiscount);
        }

        uint256 expiryTime = checkExpiry(user);
        if (expiryTime >= block.timestamp) {
            return (true, _membershipDiscount);
        }

        return (false, 0);
    }

    function checkExpiry(address user) public view returns (uint256) {
        if (_hasNonExpiryPlan[user]) {
            return block.timestamp + 36500 days;
        }

        if (_subscribers[user]) {
            return _subscriptionTime[user] + 30 days;
        }

        return 0;
    }

    function recover() public {
        uint256 amountToRecover = address(this).balance;
        require(amountToRecover > 0, "Nothing to recover");
        (bool recovered, ) = treasury.call{value: amountToRecover}("");
        require(recovered, "Failed to recover ether");
    }

    receive() external payable {
        recover();
    }
}
