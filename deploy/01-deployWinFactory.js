const { getNamedAccounts } = require("hardhat");
const { devChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async (hre) => {
  const { deployments, network } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  console.log("Deploying...");
  const WinFactory = await deploy("WinFactory", {
    from: deployer,
    args: [],
    log: true,
  });

  if (!devChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...");
    await verify(WinFactory.address, []);
  }
};

module.exports.tags = (["all"], ["factory"]);
