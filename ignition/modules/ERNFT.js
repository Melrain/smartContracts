const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules');

const DeployModule = buildModule('TokenModule', (m) => {
  const ernft = m.contract('ERNFT');
  return ernft;
});

module.exports = DeployModule;
