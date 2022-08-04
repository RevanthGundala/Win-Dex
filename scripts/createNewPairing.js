const { ethers } = require("ethers");

const { WBTC, USDC } = require("../helper-hardhat-config");

// this script will create a new pairing
async function main() {
  const WinFactory = await ethers.getContract("WinFactory");

  // WBTC / USDC Pairing

  const pair = WinFactory.createNewPairing(WBTC, USDC);

  console.log(`New pairing created: ${pair}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
