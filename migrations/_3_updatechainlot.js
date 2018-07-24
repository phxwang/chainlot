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
			drawInterval = 50000;
			poolnum = 5;
		}
		else {

			web3.personal.unlockAccount("0xd3db3028e92d98ce48e5e21256696d2e5ae04d9e", "DdfMb6chaGwjchGkp", 0);
			drawInterval = 50000;
			poolnum = 1;
		}
	

		await deployer.deploy(ChainLot, 70, 25, 5, 1, 1e16, drawInterval, 
				[0,1,1e16,
				1,1,2e16,
				2,1,5e16,
				3,0,5e16,
				3,1,1e18,
				4,0,2.5e18,
				4,1,5e19,
				5,0,5e21,
				5,1,1e64
				]);
		await deployer.deploy(ChainLotPoolFactory);

		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let factory = await ChainLotPoolFactory.deployed();
		let chainlotcoin = await ChainLotCoin.deployed();
		let chainlottoken = await ChainLotToken.deployed();
		let chainlotpublic = await ChainLotPublic.deployed();
		let drawingtool = await DrawingTool.deployed();

		await chainlotpublic.setChainLotAddress(chainlot.address);
		await chainlot.setChainLotTicketAddress(chainlotticket.address);
		await chainlot.setChainLotCoinAddress(chainlotcoin.address);
		await chainlot.setChainLotTokenAddress(chainlottoken.address);
		await chainlot.setChainLotPoolFactoryAddress(factory.address);
		await chainlotticket.setMinter(chainlot.address, true);
		await chainlottoken.setMinter(chainlot.address, true);
		await factory.transferOwnership(chainlot.address);

		for(i=0; i<poolnum; i++) {
			console.log("new pool progress: " + i);
			let r = await chainlot.newPool();
			console.log(JSON.stringify(r.logs))
		}
	}

	
};
