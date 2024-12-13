import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
require('dotenv').config();

if (!process.env.ALCHEMY_RPC_URL || !process.env.METAMASK_PRIVATE_KEY) {
  throw new Error('Please set your URL and PRIVATE_KEY in .env file');
}

const config: HardhatUserConfig = {
  solidity: '0.8.24',
  networks: {
    arb_sepolia: {
      url: process.env.ALCHEMY_RPC_URL,
      accounts: [process.env.METAMASK_PRIVATE_KEY],
    },
  },
};

export default config;
