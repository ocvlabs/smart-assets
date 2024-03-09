// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IMembership {
    function subscribe(address user) external payable returns (bool);

    function viewMembership(
        address user
    ) external view returns (bool isActive, uint256 discount);
}
