import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  const Tyrants = await ethers.getContractFactory('Tyrants');
  const tyrants = await Tyrants.deploy('0x51e75172C81D6a032CfB35D0D32B01810DD50107');
  tyrants.deploymentTransaction()?.wait();

  console.log(`Tyrants address: ${tyrants.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
