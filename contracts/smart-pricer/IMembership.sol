// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IMembership {
    function viewMembership(
        address user
    ) external view returns (bool isActive, uint256 discount);
}
