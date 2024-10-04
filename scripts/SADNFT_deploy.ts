import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  const TheDingCoin = await ethers.getContractFactory('NFTMarketplace');
  const theDingCoin = await TheDingCoin.deploy('0xD94e9ac67dcA7F8A1157ca013D975e5aCd22E206');
  theDingCoin.deploymentTransaction()?.wait();

  console.log(`NFTMarketplace address: ${theDingCoin.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
