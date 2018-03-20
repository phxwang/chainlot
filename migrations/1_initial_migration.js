var Migrations = artifacts.require("./Migrations.sol");
var ChainLot = artifacts.require("./ChainLot.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(ChainLot, 70, 25, 1e10, 10);
};
