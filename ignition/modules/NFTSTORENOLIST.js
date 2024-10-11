const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const DeployModule = buildModule("TokenModule", (m) => {
  const marketPlace = m.contract("NFTSTORE_NOLIST");
  return marketPlace;
});

module.exports = DeployModule;