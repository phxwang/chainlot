var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");


module.exports = async function(deployer, network) {
	if (network == "rinkeby" || network == "main") {
		if(network == "rinkeby") 
			web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0);
		else
			web3.personal.unlockAccount("0xd3db3028e92d98ce48e5e21256696d2e5ae04d9e", "DdfMb6chaGwjchGkp", 0);

		await Promise.all([
			deployer.deploy(DrawingTool)
		]);

		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let factory = await ChainLotPoolFactory.deployed();
		let cltoken = await CLToken.deployed();
		let chainlotpublic = await ChainLotPublic.deployed();
		let drawingtool = await DrawingTool.deployed();

		//console.log("ChainLotPublic: " + chainlotpublic.address);

		await drawingtool.init(chainlotticket.address, cltoken.address);

	}

	
	 
};
