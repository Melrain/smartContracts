// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract StoneCoin is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("StoneCoin", "STONE") ERC20Permit("StoneCoin") {
        _mint(msg.sender, 20000000 * 10 ** decimals());
    }
}
