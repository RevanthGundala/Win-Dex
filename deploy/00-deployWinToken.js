const { getNamedAccounts } = require("hardhat");
const { devChains, INITIAL_SUPPLY } = require("../helper-hardhat-config");

module.exports = async (hre) => {
  const { deployments, network } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  if (!devChains.includes(network.name)) {
    console.log("Deploying... ");
    const WinToken = await deploy("WinToken", {
      from: deployer,
      args: [INITIAL_SUPPLY],
      log: true,
      waitForBlockConfirmations: 1,
    });
  }
};

module.exports.tags = (["all"], ["token"]);
