const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  let NFTMarketplace, nftMarketplace;
  let owner, addr1, addr2, addr3;

  beforeEach(async function () {
    NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    nftMarketplace = await NFTMarketplace.deploy(20); // 20% listing fee
    await nftMarketplace.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async () => {
      const marketplaceOwner = await nftMarketplace.marketplaceOwner();
      expect(marketplaceOwner).to.equal(owner.address);
    });

    it("Should set the listing fee percentage correctly", async function () {
      const listingFeePercent = await nftMarketplace.listingFeePercent();
      expect(listingFeePercent).to.equal(20);
    });
  });

  describe("Creating NFTs", function () {
    it("Should create a new token and emit TokenCreated event", async function () {
      const tokenId = 1;
      const tokenURI = "https://example.com/nft1";

      await expect(nftMarketplace.createToken(tokenId, tokenURI))
        .to.emit(nftMarketplace, "TokenCreated")
        .withArgs(tokenId);

      const tokenOwner = await nftMarketplace.ownerOf(tokenId);
      expect(tokenOwner).to.equal(owner.address);

      const tokenURIFromContract = await nftMarketplace.tokenURI(tokenId);
      expect(tokenURIFromContract).to.equal(tokenURI);
    });
  });

  describe("Listing NFTs", function () {
    it("Should list an NFT for sale and emit TokenListed event", async function () {
      const tokenId = 1;
      const price = ethers.utils.parseEther("1");
      const tokenURI = "https://example.com/nft1";

      await nftMarketplace.createToken(tokenId, tokenURI);
      await expect(nftMarketplace.listToken(tokenId, price))
        .to.emit(nftMarketplace, "TokenListed")
        .withArgs(tokenId, price);

      const listing = await nftMarketplace.tokenIdToListing(tokenId);
      expect(listing.isListed).to.be.true;
      expect(listing.price).to.equal(price);
    });
  });

  describe("Sales Execution", function () {
    beforeEach(async function () {
      const tokenId = 1;
      const tokenURI = "https://example.com/nft";
      await nftMarketplace.createToken(tokenId, tokenURI);
      await nftMarketplace.listToken(tokenId, ethers.utils.parseEther("1"));
    });

    it("Should execute the sale of an NFT", async function () {
      const tokenId = 1;
      const price = ethers.utils.parseEther("1");

      await expect(nftMarketplace.connect(addr1).executeSale(tokenId, { value: price }))
        .to.emit(nftMarketplace, "TokenSold")
        .withArgs(tokenId, addr1.address, price);

      const listing = await nftMarketplace.tokenIdToListing(tokenId);
      expect(listing.isListed).to.be.false;
      expect(listing.seller).to.equal(addr1.address);
    });

    it("Should fail if the payment amount is incorrect", async function () {
      const tokenId = 1;
      const incorrectPrice = ethers.utils.parseEther("0.5");

      await expect(nftMarketplace.connect(addr1).executeSale(tokenId, { value: incorrectPrice }))
        .to.be.revertedWith("Please submit the asking price to complete the purchase");
    });
  });

  describe("Updating Listing Fee", function () {
    it("Should allow the owner to update the listing fee percentage", async function () {
      await nftMarketplace.updateListingFeePercent(10);
      const listingFeePercent = await nftMarketplace.listingFeePercent();
      expect(listingFeePercent).to.equal(10);
    });

    it("Should reject listing fee updates from non-owner addresses", async function () {
      await expect(nftMarketplace.connect(addr1).updateListingFeePercent(10)).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Retrieving NFTs", function () {
    beforeEach(async function () {
      const tokenId1 = 1;
      const tokenId2 = 2;
      const tokenURI1 = "https://example.com/nft1";
      const tokenURI2 = "https://example.com/nft2";
      await nftMarketplace.createToken(tokenId1, tokenURI1);
      await nftMarketplace.createToken(tokenId2, tokenURI2);
      await nftMarketplace.listToken(tokenId1, ethers.utils.parseEther("1"));
      await nftMarketplace.listToken(tokenId2, ethers.utils.parseEther("1"));
    });

    it("Should retrieve all NFTs owned by the caller", async function () {
      const myTokens = await nftMarketplace.getMyTokens();
      expect(myTokens).to.have.lengthOf(2);
      expect(myTokens[0].toString()).to.equal('1');
      expect(myTokens[1].toString()).to.equal('2');
    });
  });
});
