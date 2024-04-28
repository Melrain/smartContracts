// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TheDingCoin is ERC20, Ownable, ERC20Permit {
    constructor(
        address initialOwner
    )
        ERC20("TheDingCoin", "TDC")
        Ownable(initialOwner)
        ERC20Permit("TheDingCoin")
    {
        _mint(address(this), 100000000 * 10 ** decimals());
        _mint(msg.sender, 198900 * 10 ** decimals());
    }

    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }

    function getContractBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function ownerSendCoin(address to, uint256 amount) public onlyOwner {
        _transfer(address(this), to, amount);
    }
}
