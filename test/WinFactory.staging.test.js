const { assert, expect } = require("chai");
const { getNamedAccounts, ethers, deployments, network } = require("hardhat");
const { devChains, TOKEN_A, TOKEN_B } = require("../helper-hardhat-config");

devChains.includes(network.name)
  ? describe.skip
  : describe("WinFactory", function () {
      let winFactory;
      beforeEach(async function () {
        const { deployer } = await getNamedAccounts();
        winFactory = await ethers.getContract("WinFactory", deployer);
      });
      describe("Create New Pairing", function () {
        it("Should revert if first token is non-existent", async function () {
          await expect(
            winFactory.createNewPairing(ethers.constants.AddressZero, TOKEN_B)
          ).to.be.revertedWith("WinDex__ZeroAddress");
        });
        it("Should revert if second token is non-existent", async function () {
          await expect(
            winFactory.createNewPairing(
              TOKEN_A,
              "0x00000000000000000000000000000000"
            )
          ).to.be.revertedWith("WinDex__ZeroAddress");
        });
        it("Should revert if tokens are the same", async function () {
          await expect(
            winFactory.createNewPairing(TOKEN_A, TOKEN_A)
          ).to.be.revertedWith("WinDex__IdenticalAddress");
        });
        it("Should revert if pair already exists", async function () {
          const pair = await winFactory.createNewPairing(TOKEN_A, TOKEN_B);
          await pair.wait(1);
          await expect(
            winFactory
              .createNewPairing(TOKEN_A, TOKEN_B)
              .to.be.revertedWith("WinDex__PairAlreadyExists")
          );
        });
        it("should correctly create the pair", async function () {
          const pair = await winFactory.createNewPairing(TOKEN_A, TOKEN_B);
          assert(pair.toString().length == 32);
        });
        it("should correctly add the pair to the array", async function () {
          const pair = await winFactory.createNewPairing(TOKEN_A, TOKEN_B);
          await pair.wait(1);
          assert(pair == winFactory.s_liquidityPool(0));
        });
        it("should correctly emit the pair added event", async function () {
          await expect(winFactory.createNewPairing(TOKEN_A, TOKEN_B)).to.emit(
            winFactory,
            "pairingCreated"
          );
        });
      });
      describe("Delete Pairing", function () {
        it("Should revert if pair does not exist", async function () {
          await expect(
            winFactory
              .deletePairing(TOKEN_A, TOKEN_B)
              .to.be.revertedWith("WinDex__PairDoesNotExist")
          );
        });
        it("should correctly delete the pairing from the array", async function () {
          const pair = await winFactory.createNewPairing(TOKEN_A, TOKEN_B);
          await pair.wait(1);
          await winFactory.deletePairing(pair);
          assert(winFactory.s_liquidityPool(0) == null);
        });
        it("should correctly emit the pair deleted event", async function () {
          const pair = await winFactory.createNewPairing(TOKEN_A, TOKEN_B);
          await pair.wait(1);
          await expect(
            winFactory.deletePairing(pair).to.emit(winFactory, "pairingDeleted")
          );
        });
      });
      describe("Get Number of pairs", function () {
        it("should correctly get the number of pairs in the array", async function () {
          // const num = await winFactory.getNumPairs();
          // assert.equal(num.toString(), "0");

          const tx = await winFactory.createNewPairing(TOKEN_A, TOKEN_B);
          await tx.wait(1);
          const num1 = await winFactory.getNumPairs();
          assert.equal(num1.toString(), "1");
        });
      });
      describe("Get Pair", function () {
        it("Should revert if first token is non-existent", async function () {
          await expect(
            winFactory.createNewPairing(
              "0x00000000000000000000000000000000",
              TOKEN_B
            )
          ).to.be.revertedWith("WinDex__ZeroAddress");
        });
        it("Should revert if second token is non-existent", async function () {
          await expect(
            winFactory.createNewPairing(
              TOKEN_A,
              "0x00000000000000000000000000000000"
            )
          ).to.be.revertedWith("WinDex__ZeroAddress");
        });
        it("Should revert if tokens are the same", async function () {
          await expect(
            winFactory.createNewPairing(TOKEN_A, TOKEN_A)
          ).to.be.revertedWith("WinDex__IdenticalAddress");
        });
        it("Should revert if the pair does not exist", async function () {
          await expect(
            winFactory
              .getPair(TOKEN_A, TOKEN_B)
              .to.be.revertedWith("WinDex__PairDoesNotExist")
          );
        });
        it("should correctly get the pair address", async function () {
          const pair = await winFactory.createNewPairing(TOKEN_A, TOKEN_B);
          await pair.wait(1);
          const _pair = await winFactory.getPair(TOKEN_A, TOKEN_B);
          await _pair.wait(1);
          assert(pair.toString() == _pair.toString());
        });
      });
    });
