var Migrations = artifacts.require("./Migrations.sol");
var ChainLot = artifacts.require("./ChainLot.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  //deployer.deploy(ChainLot, 70, 25, 5, 1, 1e10, 2, [5,1,1e64,5,0,1e14,4,1,5e13,4,0,2.5e12,3,1,1e12,3,0,5e10,2,1,5e10,1,1,2e10,0,1,1e10]);
  //deployer.deploy(ChainLot, 5, 5, 2, 1, 1e10, 2, [2,1,1e64,2,0,1e12,1,1,5e11,0,1,1e10]);
  deployer.deploy(ChainLot, 2, 2, 1, 1, 1e10, 2, [1,1,2e16,0,1,1e10]);
};
