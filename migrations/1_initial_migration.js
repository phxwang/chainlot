var Migrations = artifacts.require("./Migrations.sol");

module.exports = function(deployer, network) {
	if (network == "rinkeby" || network == "main") {
		if(network == "rinkeby") {
			web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0);
		}
		else {

				web3.personal.unlockAccount("0xd3db3028e92d98ce48e5e21256696d2e5ae04d9e", "DdfMb6chaGwjchGkp", 0);

		}
	}
	deployer.deploy(Migrations);
};