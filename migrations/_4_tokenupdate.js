var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");
var ChainLotToken = artifacts.require("./ChainLotToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");


module.exports = async function(deployer, network) {
	if (network == "rinkeby" || network == "main") {
		if(network == "rinkeby") {
			web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0);
			drawInterval = 100;
			poolnum = 5;
		}
		else {

			web3.personal.unlockAccount("0xd3db3028e92d98ce48e5e21256696d2e5ae04d9e", "DdfMb6chaGwjchGkp", 0);
			drawInterval = 50000;
			poolnum = 1;
		}
	
		await Promise.all([
			deployer.deploy(ChainLotToken, 1e9, 1e13, 5e7),
		]);

		let chainlot = await ChainLot.deployed();
		let chainlottoken = await ChainLotToken.deployed();
		
		await chainlot.setChainLotTokenAddress(chainlottoken.address);
		await chainlottoken.setMinter(chainlot.address, true);
	}

	
};
