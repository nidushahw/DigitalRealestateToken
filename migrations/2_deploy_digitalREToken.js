const DigitalREToken = artifacts.require("DigitalREToken");

module.exports = function(deployer) {
  deployer.deploy(DigitalREToken, "Digital REToken", "DRET");
}
