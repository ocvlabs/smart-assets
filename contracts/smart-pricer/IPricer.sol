//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPricer {
    function price(
        address user,
        uint256 code
    ) external view returns (address token, uint256 price);
}
