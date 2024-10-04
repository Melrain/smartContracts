const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const DeployModule = buildModule("TokenModule", (m) => {
  const listingFeePercent = 5; // 设置 listingFeePercent 的值
  const marketPlace = m.contract("NFTMarketplace",listingFeePercent);
  return marketPlace;
});

module.exports = DeployModule;