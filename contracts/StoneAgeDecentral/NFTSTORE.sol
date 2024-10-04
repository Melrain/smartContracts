// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTSTORE is ERC721URIStorage {
    uint256 public listingFeePercent;
    uint256 public totalItemsSold;
    address payable public marketplaceOwner;
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

    modifier onlyOwner() {
        require(
            msg.sender == marketplaceOwner,
            "Only owner can call this function"
        );
        _;
    }

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    constructor() ERC721("StoneAgeDecentral NFT", "SADNFT") {
        listingFeePercent = 5; // Default listing fee is 5%
        marketplaceOwner = payable(msg.sender);
    }

    function createToken(
        uint256 tokenId,
        string memory tokenURI,
        uint256 price
    ) public onlyOwner {
        require(price > 0, "Price must be greater than zero");

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        ownerToTokenIds[msg.sender].push(tokenId);

        _listToken(tokenId, price, payable(msg.sender));

        emit TokenCreated(tokenId, price);
    }

    function _listToken(
        uint256 tokenId,
        uint256 price,
        address payable seller
    ) internal {
        NFTListing storage listing = tokenIdToListing[tokenId];
        listing.tokenId = tokenId;
        listing.price = price;
        listing.seller = seller;
        listing.isListed = true;

        emit TokenListed(tokenId, price);
    }

    function listToken(uint256 tokenId, uint256 price) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(price > 0, "Price must be greater than zero");

        _listToken(tokenId, price, payable(msg.sender));
    }

    function executeSale(uint256 tokenId) public payable noReentrancy {
        NFTListing storage listing = tokenIdToListing[tokenId];
        uint256 price = listing.price;
        address payable seller = listing.seller;
        uint256 tolerance = 1 ether; // You can adjust the tolerance as needed

        require(
            msg.value + tolerance >= price,
            "Please submit the asking price to complete the purchase"
        );
        require(listing.isListed, "This token is not listed for sale");

        listing.seller = payable(msg.sender);
        listing.isListed = false;
        totalItemsSold++;

        _transfer(ownerOf(tokenId), msg.sender, tokenId);

        // Update owner to token ids mapping
        _removeTokenFromOwnerEnumeration(seller, tokenId);
        ownerToTokenIds[msg.sender].push(tokenId);

        uint256 listingFee = (price * listingFeePercent) / 100;

        // Ensure successful transfers
        // Transfer listing fee to marketplace owner
        safeTransferETH(marketplaceOwner, listingFee);
        // Transfer the remaining amount to seller
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

        _listToken(tokenId, price, payable(msg.sender));
    }

    function getMyTokens() public view returns (uint256[] memory) {
        return ownerToTokenIds[msg.sender];
    }

    function getMyListedTokens() public view returns (NFTListing[] memory) {
        uint256 totalItemCount = 0;
        uint256 currentIndex = 0;
        uint256[] memory myTokens = ownerToTokenIds[msg.sender];

        // Get the total number of listed NFTs for caller
        for (uint256 i = 0; i < myTokens.length; i++) {
            uint256 tokenId = myTokens[i];
            if (tokenIdToListing[tokenId].isListed) {
                totalItemCount++;
            }
        }

        // Create an array for caller's listed NFTs
        NFTListing[] memory items = new NFTListing[](totalItemCount);
        for (uint256 i = 0; i < myTokens.length; i++) {
            uint256 tokenId = myTokens[i];
            if (tokenIdToListing[tokenId].isListed) {
                items[currentIndex] = tokenIdToListing[tokenId];
                currentIndex++;
            }
        }

        return items;
    }

    function getAllListedNFTs() public view returns (NFTListing[] memory) {
        uint256 totalItemCount = 0;
        uint256 currentIndex = 0;

        // Get the total number of listed NFTs
        for (uint256 i = 0; i < ownerToTokenIds[marketplaceOwner].length; i++) {
            uint256 tokenId = ownerToTokenIds[marketplaceOwner][i];
            if (tokenIdToListing[tokenId].isListed) {
                totalItemCount++;
            }
        }

        // Create an array for listed NFTs
        NFTListing[] memory items = new NFTListing[](totalItemCount);
        for (uint256 i = 0; i < ownerToTokenIds[marketplaceOwner].length; i++) {
            uint256 tokenId = ownerToTokenIds[marketplaceOwner][i];
            if (tokenIdToListing[tokenId].isListed) {
                items[currentIndex] = tokenIdToListing[tokenId];
                currentIndex++;
            }
        }

        return items;
    }

    function isTokenListed(uint256 tokenId) public view returns (bool) {
        return tokenIdToListing[tokenId].isListed;
    }

    function safeTransferETH(
        address payable recipient,
        uint256 amount
    ) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function updateListingFeePercent(
        uint256 _listingFeePercent
    ) public onlyOwner {
        listingFeePercent = _listingFeePercent;
    }

    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId
    ) private {
        uint256 lastTokenIndex = ownerToTokenIds[from].length - 1;
        uint256 tokenIndex;

        for (uint256 i = 0; i < ownerToTokenIds[from].length; i++) {
            if (ownerToTokenIds[from][i] == tokenId) {
                tokenIndex = i;
                break;
            }
        }

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownerToTokenIds[from][lastTokenIndex];
            ownerToTokenIds[from][tokenIndex] = lastTokenId;
        }

        ownerToTokenIds[from].pop();
    }
}
