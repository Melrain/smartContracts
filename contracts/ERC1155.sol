// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MyToken is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant HAMMER = 2;

    uint256 public listingFeePercent;
    address payable public marketplaceOwner;
    uint256 public totalItemsSold;
    bool private locked;

    struct NFTListing {
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool isListed;
    }

    mapping(uint256 => NFTListing) public tokenIdToListing;
    mapping(address => uint256[]) public ownerToTokenIds;

    event TokenCreated(uint256 tokenId, uint256 price);
    event TokenListed(uint256 tokenId, uint256 price);
    event TokenSold(uint256 tokenId, address buyer, uint256 price);
    event TokenUnlisted(uint256 tokenId);

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {
        _mint(msg.sender, GOLD, 1000000, "");
        _mint(msg.sender, SILVER, 50505, "");
        _mint(msg.sender, HAMMER, 1, "");
        listingFeePercent = 5;
        marketplaceOwner = payable(msg.sender);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
