import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  const ERNFT = await ethers.getContractFactory('ERNFT');
  const ernft = await ERNFT.deploy({
    from: '0x51e75172C81D6a032CfB35D0D32B01810DD50107',
  });
  ernft.deploymentTransaction()?.wait();

  console.log(`ERNFT address: ${ernft.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
