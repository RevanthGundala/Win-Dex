const { ethers, network } = require("hardhat");
const fs = require("fs");

const FRONT_END_ADDRESSES_FILE =
  "/Users/revanthgundala/dex-frontend/constants/contractAddresses.json";
const FRONT_END_ABI_FILE =
  "/Users/revanthgundala/dex-frontend/constants/abi.json";

module.exports = async function () {
  if (process.env.UPDATE_FRONT_END) {
    console.log("Updating front end...");
    updateContractAddresses();
    updateAbi();
    console.log("updated!");
  }
};

async function updateContractAddresses() {
  const winPair = await ethers.getContract("WinPair");
  const chainId = network.config.chainId.toString();
  const currentAddresses = JSON.parse(
    fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8")
  );

  if (chainId in currentAddresses) {
    if (!currentAddresses[chainId].includes(winPair.address)) {
      currentAddresses[chainId].push(winPair.address);
    }
  } else {
    currentAddresses[chainId] = [winPair.address];
  }

  fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(currentAddresses));
}

async function updateAbi() {
  const winPair = await ethers.getContract("WinPair");
  fs.writeFileSync(
    FRONT_END_ABI_FILE,
    winPair.interface.format(ethers.utils.FormatTypes.json)
  );
}

module.exports.tags = ["all", "frontend"];
