const { getNamedAccounts } = require("hardhat");
const {
  devChains,
  TOKEN_A,
  TOKEN_B,
  USDC,
  WBTC,
} = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async (hre) => {
  const { deployments, network } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  const WinPair = await deploy("WinPair", {
    from: deployer,
    args: [USDC, WBTC],
    log: true,
  });

  if (!devChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...");
    await verify(WinPair.address, [USDC, WBTC]);
  }
};

module.exports.tags = (["all"], ["pair"]);
