var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");


module.exports = async function(deployer, network) {
	if(network == "develop") {
		console.log("develop");
		await Promise.all([
			deployer.deploy(ChainLot, 2, 2, 2, 1, 1e10, 10, [0,1,1e10, 2,1,2e16]),
			//deployer.deploy(ChainLot, 70, 25, 5, 1, 1e10, 10, [0,1,1e10, 2,1,2e16]),
			deployer.deploy(ChainLotTicket),
			deployer.deploy(CLToken, 100000000000),
			deployer.deploy(ChainLotPoolFactory),
			deployer.deploy(ChainLotPublic),
			deployer.deploy(DrawingTool)
		]);

	}
	else if (network == "rinkeby" || network == "main") {
		if(network == "rinkeby") 
			web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0);
		else
			web3.personal.unlockAccount("0xd3db3028e92d98ce48e5e21256696d2e5ae04d9e", "DdfMb6chaGwjchGkp", 0);
		if(network == "rinkeby")
			drawInterval = 100;
		else
			drawInterval = 50000;
		await Promise.all([
			deployer.deploy(ChainLotPublic),
			deployer.deploy(ChainLot, 70, 25, 5, 1, 1e16, drawInterval, [5,1,1e64,5,0,5e21,4,1,5e19,4,0,2.5e18,3,1,1e18,3,0,5e16,2,1,5e16,1,1,2e16,0,1,1e16]),
			deployer.deploy(ChainLotTicket),
			deployer.deploy(CLToken, 1e12),
			deployer.deploy(ChainLotPoolFactory),
			deployer.deploy(DrawingTool)
		]);

		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let factory = await ChainLotPoolFactory.deployed();
		let cltoken = await CLToken.deployed();
		let chainlotpublic = await ChainLotPublic.deployed();
		let drawingtool = await DrawingTool.deployed();

		console.log("ChainLotPublic: " + chainlotpublic.address);

		await chainlotpublic.setChainLotAddress(chainlot.address);
		await chainlotpublic.setCLTokenAddress(cltoken.address);
		await chainlotpublic.setChainLotTicketAddress(chainlotticket.address);
		await chainlot.setChainLotTicketAddress(chainlotticket.address);
		await chainlot.setCLTokenAddress(cltoken.address);
		await chainlot.setChainLotPoolFactoryAddress(factory.address);
		await chainlotticket.setMinter(chainlot.address, true);
		await factory.transferOwnership(chainlot.address);
		await drawingtool.init(chainlotticket.address, cltoken.address);


		for(i=0; i<5; i++) {
			console.log("new pool progress: " + i);
			let r = await chainlot.newPool();
			console.log(JSON.stringify(r.logs))
		}

	}

	
};
