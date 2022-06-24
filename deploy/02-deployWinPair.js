const { getNamedAccounts } = require("hardhat");
const { devChains, TOKEN_A, TOKEN_B } = require("../helper-hardhat-config");

module.exports = async (hre) => {
  const { deployments, network } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  if (!devChains.includes(network.name)) {
    const WinPair = await deploy("WinPair", {
      from: deployer,
      args: [TOKEN_A, TOKEN_B],
      log: true,
      waitForBlockConfirmations: 6,
    });
  }
};

module.exports.tags = (["all"], ["pair"]);
