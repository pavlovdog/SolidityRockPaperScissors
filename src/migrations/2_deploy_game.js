const mainContract = artifacts.require("./Main.sol");

module.exports = function(deployer) {
  deployer.deploy(mainContract);
};
