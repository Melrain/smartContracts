// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage {
    uint256 public listingFeePercent;
    uint256 public totalItemsSold;
    address payable public marketplaceOwner;

    struct NFTListing {
        uint256 tokenId;
        uint256 price;
        address payable owner;
        address payable seller;
        bool isListed;
    }

    mapping(uint256 => NFTListing) public tokenIdToListing;
    mapping(address => uint256[]) public ownerToTokenIds;

    modifier onlyOwner() {
        require(
            msg.sender == marketplaceOwner,
            "Only owner can call this function"
        );
        _;
    }

    event TokenCreated(uint256 tokenId);
    event TokenListed(uint256 tokenId, uint256 price);
    event TokenSold(uint256 tokenId, address buyer, uint256 price);

    constructor(uint256 _listingFeePercent) ERC721("NFTMarketplace", "NFTM") {
        listingFeePercent = _listingFeePercent;
        marketplaceOwner = payable(msg.sender);
    }

    function createToken(
        uint256 tokenId,
        string memory tokenURI
    ) public payable onlyOwner {
        // 这里可以添加可选的铸造费用逻辑
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        ownerToTokenIds[msg.sender].push(tokenId);
        emit TokenCreated(tokenId);
    }

    function listToken(uint256 tokenId, uint256 price) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(price > 0, "Price must be greater than zero");

        NFTListing storage listing = tokenIdToListing[tokenId];
        listing.tokenId = tokenId;
        listing.price = price;
        listing.owner = payable(msg.sender);
        listing.seller = payable(msg.sender);
        listing.isListed = true;

        emit TokenListed(tokenId, price);
    }

    function executeSale(uint256 tokenId) public payable {
        NFTListing storage listing = tokenIdToListing[tokenId];
        uint256 price = listing.price;
        address payable seller = listing.seller;

        require(
            msg.value == price,
            "Please submit the asking price to complete the purchase"
        );
        require(listing.isListed, "This token is not listed for sale");

        listing.seller = payable(msg.sender);
        listing.isListed = false;
        totalItemsSold++;

        _transfer(listing.owner, msg.sender, tokenId);
        listing.owner = payable(msg.sender);

        uint256 listingFee = (price * listingFeePercent) / 100;

        // 通过call方法确保转账成功
        safeTransferETH(marketplaceOwner, listingFee);
        safeTransferETH(seller, msg.value - listingFee);

        emit TokenSold(tokenId, msg.sender, price);
    }

    function relistToken(uint256 tokenId, uint256 price) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(price > 0, "Price must be greater than zero");

        NFTListing storage listing = tokenIdToListing[tokenId];
        require(!listing.isListed, "The NFT is already listed");

        listing.price = price;
        listing.isListed = true;
        listing.seller = payable(msg.sender);

        emit TokenListed(tokenId, price);
    }

    function getMyTokens() public view returns (uint256[] memory) {
        return ownerToTokenIds[msg.sender];
    }

    function safeTransferETH(
        address payable recipient,
        uint256 amount
    ) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
    }
}
