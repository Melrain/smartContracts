import { ethers } from 'hardhat';

async function main() {
  const [deploy] = await ethers.getSigners();

  console.log(`部署合约的地址: ${deploy.address}`);

  const SAD_Weapon = await ethers.getContractFactory('StoneAgeDecentral');
  const sad_weapon = await SAD_Weapon.deploy('0x51e75172C81D6a032CfB35D0D32B01810DD50107');
  sad_weapon.deploymentTransaction()?.wait();

  console.log(`合约地址: ${sad_weapon.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
