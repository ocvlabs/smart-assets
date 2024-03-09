//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IPricer} from "./IPricer.sol";

contract FixedPricer is IPricer {
    uint256 public _fee;
    address public _tokenAddress;

    constructor(uint256 fee, address tokenAddress) {
        _fee = fee;
        _tokenAddress = tokenAddress; // @note ERC-20 Address
    }

    function price(
        address,
        uint256
    ) public view virtual returns (address tokenAddress, uint256 fee) {
        fee = _fee;
        tokenAddress = _tokenAddress;
    }
}
