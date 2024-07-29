// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private dec;

    constructor(string memory name, string memory symbol, uint256 initialSupply, uint8 _decimals) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10 ** uint256(_decimals)));
        dec = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return dec;
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount * (10 ** uint256(dec)));}
}