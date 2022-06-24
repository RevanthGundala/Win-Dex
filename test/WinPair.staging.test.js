const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { devChains, TOKEN_A, TOKEN_B, myAccount, testAccount1 } = require("../helper-hardhat-config");

const balance = ethers.utils.parseEther("10");

devChains.includes(network.name)
  ? describe.skip
  : describe("WinPair", function () {
      let winPair;
      beforeEach(async function () {
        const { deployer } = await getNamedmyAccounts();
        winPair = await ethers.getContract("WinPair", deployer);
      });
      describe("swap", function () {
        it("should revert if there is not enough liquidity for Token A", async function () {
          await expect(
            winPair
              .swap(TOKEN_A, "4")
              .to.be.revertedWith("WinPair__ZeroLiquidity")
          );
        });
        it("should revert if there is not enough liquidity for Token B", async function () {
          await expect(
            winPair
              .swap(TOKEN_B, "4")
              .to.be.revertedWith("WinPair__ZeroLiquidity")
          );
        });
        it("should revert if the user does not have enough money", async function () {
            await expect(winPair.swap(TOKEN_A, "4").to.be.revertedWith("WinPair__InsufficientBalance"))
        })
        it("should correctly identify which token needs to be swapped, and which one is being recieved by the DEX", async function () {
          const tx = await winPair.swap(TOKEN_A, "4");
          await tx.wait(1);
          assert(winPair.tokenToBeSwapped() == TOKEN_A);
          assert(winPair.tokenToBeReceived() == TOKEN_B);
        });
        it("should subtract the trading fee from the user making the withdrawal", async function () {
            winPair.balanceOfUser(myAccount) += balance;
            const tx = await winPair.swap(TOKEN_A, "4");
            await tx.wait(1);
            
          assert(winPair.balanceOfUser(myAccount) < winPair.balanceOfUser(myAccount) - winPair.TRADING_FEE);
        });
        it("should distribute trading fee to all liquidity providers", async function() {
            const tx1 = await winPair.s_liquidityProviders.push(testAccount1);
            await tx1.wait(1);

            const tx2 = await winPair.swap(TOKEN_A, "4");
            await tx2.wait(1);
            assert(winPair.balanceOfUser(testAccount1) == winPair.TRADING_FEE);

            const tx3 = await winPair.s_liquidityProviders.push(myAccount);
            await tx3.wait(1);
            
            const tx4 = await winPair.swap(TOKEN_A, "4");
            await tx4.wait(1);
            assert(winPair.balanceOfUser(myAccount) == winPair.TRADING_FEE / 2);
            // possibly need to convert to ether ^^
            
        })
      });
    });
