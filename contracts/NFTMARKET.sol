// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTMARKET is ERC721URIStorage {
    uint256 public listingFeePercent;
    uint256 public totalItemsSold;
    address payable public marketplaceOwner;
    bool private locked;
    uint256[] private listedTokenIds;
    uint256[] private allTokenIds; // To track all token IDs
    mapping(address => uint256) private deposits; // New mapping to track deposits

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

    constructor() ERC721("NFT Market", "NFTMARKET") {
        listingFeePercent = 5; // Default listing fee is 5%
        marketplaceOwner = payable(msg.sender);
    }

    // Replace owner
    function changeMarketplaceOwner(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        marketplaceOwner = newOwner;
    }

    // New function to deposite ETH to the contract
    function depositeToContract() public payable {
        deposits[msg.sender] += msg.value;
    }

    // New function to get the amount deposited by an address
    function getMyDepositeAmount() public view returns (uint256) {
        return deposits[msg.sender];
    }

    // New function to get the total ETH balance of the contract
    function getTotalDepositedValues() public view returns (uint256) {
        return address(this).balance;
    }

    // New function for the contract owner to send ETH to a specified address
    function contractSendEthTo(
        address payable recipient,
        uint256 amount
    ) public onlyOwner {
        require(
            address(this).balance >= amount,
            "Insufficient contract balance"
        );
        recipient.transfer(amount);
    }

    function createToken(
        uint256 tokenId,
        string memory tokenURI,
        uint256 price
    ) public onlyOwner {
        require(price > 0, "Price must be greater than zero");

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        allTokenIds.push(tokenId);
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

        listedTokenIds.push(tokenId);

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

    function unlistToken(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(tokenIdToListing[tokenId].isListed, "Token is not listed");

        tokenIdToListing[tokenId].isListed = false;

        // Remove from listedTokenIds
        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                listedTokenIds.pop();
                break;
            }
        }

        emit TokenUnlisted(tokenId);
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
        safeTransferETH(marketplaceOwner, listingFee);
        safeTransferETH(seller, msg.value - listingFee);

        // Remove from listedTokenIds
        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                listedTokenIds.pop();
                break;
            }
        }

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

    function getTokenByTokenId(
        uint256 tokenId
    ) public view returns (NFTListing memory) {
        return tokenIdToListing[tokenId];
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

        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            if (tokenIdToListing[listedTokenIds[i]].isListed) {
                totalItemCount++;
            }
        }

        NFTListing[] memory items = new NFTListing[](totalItemCount);
        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            if (tokenIdToListing[listedTokenIds[i]].isListed) {
                items[currentIndex] = tokenIdToListing[listedTokenIds[i]];
                currentIndex++;
            }
        }

        return items;
    }

    function getAllTokens() public view returns (uint256[] memory) {
        return allTokenIds;
    }

    function isTokenListed(uint256 tokenId) public view returns (bool) {
        return tokenIdToListing[tokenId].isListed;
    }

    function safeTransferETH(
        address payable recipient,
        uint256 amount
    ) internal {
        Address.sendValue(recipient, amount);
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

    function transferTokenTo(address from, address to, uint256 tokenId) public {
        require(
            ownerOf(tokenId) == from,
            "Sender is not the owner of this token"
        );
        require(
            msg.sender == from || isApprovedForAll(from, msg.sender),
            "Caller is not owner nor approved"
        );
        require(
            !tokenIdToListing[tokenId].isListed,
            "Token is currently listed and cannot be transferred"
        );

        _transfer(from, to, tokenId);

        // Update the owner to token IDs mapping
        _removeTokenFromOwnerEnumeration(from, tokenId);
        ownerToTokenIds[to].push(tokenId);
    }

    function createTokenToAddress(
        uint256 tokenId,
        string memory tokenURI,
        address receiver
    ) public onlyOwner {
        _mint(receiver, tokenId);
        _setTokenURI(tokenId, tokenURI);

        allTokenIds.push(tokenId);
        ownerToTokenIds[receiver].push(tokenId);

        emit TokenCreated(tokenId, 0); // Price is 0 as it's not listed
    }
}
