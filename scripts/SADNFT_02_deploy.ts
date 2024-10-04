import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  const NFTMarketplace_02 = await ethers.getContractFactory('NFTMarketplace_02');
  const nftMarketplace_02 = await NFTMarketplace_02.deploy('0xD94e9ac67dcA7F8A1157ca013D975e5aCd22E206');
  nftMarketplace_02.deploymentTransaction()?.wait();

  console.log(`NFTMarketplace address: ${nftMarketplace_02.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
