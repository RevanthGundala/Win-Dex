const { getNamedAccounts } = require("hardhat");
const { devChains } = require("../helper-hardhat-config");

module.exports = async (hre) => {
  const { deployments, network } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  if (!devChains.includes(network.name)) {
    console.log("Deploying...");
    const WinFactory = await deploy("WinFactory", {
      from: deployer,
      args: [],
      log: true,
      waitForBlockConfirmations: 6,
    });
  }
};

module.exports.tags = (["all"], ["factory"]);
