const { run } = require("hardhat");

//auto verification for etherscan
//args = args of constructor
async function verify(contractAddress, args) {
  //args for the contract (constructor args)
  console.log("Verifying contract...");
  try {
    //run allows us to run any hardhat task
    await run("verify:verify", {
      //object that contains the actual parametesr
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      //prints errors or if its alr verified
      console.log("Already verified");
    } else {
      console.log(e);
    }
  }
}

module.exports = { verify };
