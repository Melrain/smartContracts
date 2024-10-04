import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  const NFTSTORE = await ethers.getContractFactory('NFTSTORE');
  const nftStore = await NFTSTORE.deploy('0xD94e9ac67dcA7F8A1157ca013D975e5aCd22E206');
  nftStore.deploymentTransaction()?.wait();

  console.log(`NFTMarketplace address: ${nftStore.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
