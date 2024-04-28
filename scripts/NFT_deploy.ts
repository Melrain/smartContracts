import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  const MyNft = await ethers.getContractFactory('MyNft');
  const myNft = await MyNft.deploy('0x51e75172C81D6a032CfB35D0D32B01810DD50107');
  myNft.deploymentTransaction()?.wait();

  console.log(`NFT address: ${myNft.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
