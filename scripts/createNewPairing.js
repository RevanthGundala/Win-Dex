const { ethers } = require("ethers");
const { getNamedAccounts } = require("hardhat");
const { TOKEN_A, TOKEN_B } = require("../helper-hardhat-config");

// this script will create a new pairing
async function main() {
  const { deployer } = await getNamedAccounts();

  const WinFactory = await ethers.getContract("WinToken", deployer);

  // WETH / WinToken Pairing

  const pair = WinFactory.createNewPairing(TOKEN_A, TOKEN_B);
  await pair.wait(1);

  console.log(`New pairing created: ${pair}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
