var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");
var ChainLotToken = artifacts.require("./ChainLotToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");
var AffiliateStorage = artifacts.require("./AffiliateStorage.sol");


module.exports = async function(deployer, network) {
	if(network == "develop") {
		console.log("develop");
		await Promise.all([
			deployer.deploy(ChainLot, 2, 2, 3, 0, 1e10, 10, [1,0,1e10, 40, 3,0,2e16, 48]),
			/*deployer.deploy(ChainLot, 70, 25, 5, 1, 1e6, 10000, [0,1,1e16,
				1,1,2e6,
				2,1,5e6,
				3,0,5e6,
				3,1,1e8,
				4,0,2.5e8,
				4,1,5e9,
				5,0,5e11,
				5,1,1e64
				]),*/
			deployer.deploy(ChainLotTicket),
			deployer.deploy(ChainLotCoin, 100000000000),
			deployer.deploy(ChainLotToken, 1e3, 1e10, 50),
			deployer.deploy(ChainLotPoolFactory),
			deployer.deploy(ChainLotPublic),
			deployer.deploy(DrawingTool),
			deployer.deploy(AffiliateStorage)
		]);

	}
	else if (network == "rinkeby" || network == "main") {
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
			deployer.deploy(ChainLotPublic),
			/*deployer.deploy(ChainLot, 70, 25, 5, 1, 1e16, drawInterval, 
				[0,1,1e16,
				1,1,2e16,
				2,1,5e16,
				3,0,5e16,
				3,1,1e18,
				4,0,2.5e18,
				4,1,5e19,
				5,0,5e21,
				5,1,1e64
				]),*/
			deployer.deploy(ChainLot, 100, 0, 5, 0, 1e16, drawInterval, 
				[1,0,2e16,10,
				 2,0,1e18,10,
				 3,0,5e19,5,
				 4,0,5e21,5,
				 5,0,1e60,48,
				]),
			deployer.deploy(ChainLotTicket),
			deployer.deploy(ChainLotCoin, 1e12),
			deployer.deploy(ChainLotToken, 1e9, 1e13, 5e7),
			deployer.deploy(ChainLotPoolFactory),
			deployer.deploy(DrawingTool)
		]);

		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let factory = await ChainLotPoolFactory.deployed();
		let chainlotcoin = await ChainLotCoin.deployed();
		let chainlottoken = await ChainLotToken.deployed();
		let chainlotpublic = await ChainLotPublic.deployed();
		let drawingtool = await DrawingTool.deployed();

		console.log("ChainLotPublic: " + chainlotpublic.address);

		await chainlotpublic.setChainLotAddress(chainlot.address);
		await chainlot.setChainLotTicketAddress(chainlotticket.address);
		await chainlot.setChainLotCoinAddress(chainlotcoin.address);
		await chainlot.setChainLotTokenAddress(chainlottoken.address);
		await chainlot.setChainLotPoolFactoryAddress(factory.address);
		await chainlotticket.setMinter(chainlot.address, true);
		await chainlottoken.setMinter(chainlot.address, true);
		await factory.transferOwnership(chainlot.address);
		await drawingtool.init(chainlotticket.address, chainlotcoin.address);

		for(i=0; i<poolnum; i++) {
			console.log("new pool progress: " + i);
			let r = await chainlot.newPool();
			console.log(JSON.stringify(r.logs))
		}

	}

	
};
