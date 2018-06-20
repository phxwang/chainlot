var Migrations = artifacts.require("./Migrations.sol");
var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");


module.exports = async function(deployer, network) {
	if(network == "develop") {
		await Promise.all([
			deployer.deploy(Migrations),
	 	   	deployer.deploy(ChainLot, 2, 2, 2, 1, 1e10, 10, [0,1,1e10, 2,1,2e16]),
			//deployer.deploy(ChainLot, 70, 25, 5, 1, 1e10, 10, [0,1,1e10, 2,1,2e16]),
			deployer.deploy(ChainLotTicket),
			deployer.deploy(CLToken, 100000000000),
			deployer.deploy(ChainLotPoolFactory),
			deployer.deploy(ChainLotPublic)
		]);

	}
	else if (network == "rinkeby") {
		web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0)
		await Promise.all([
			deployer.deploy(Migrations),
			deployer.deploy(ChainLot, 70, 25, 5, 1, 1e16, 100, [5,1,1e64,5,0,5e21,4,1,5e19,4,0,2.5e18,3,1,1e18,3,0,5e16,2,1,5e16,1,1,2e16,0,1,1e16]),
			deployer.deploy(ChainLotTicket),
			deployer.deploy(CLToken, 1e12),
			deployer.deploy(ChainLotPoolFactory),
			deployer.deploy(ChainLotPublic),
		]);

		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let factory = await ChainLotPoolFactory.deployed();
		let cltoken = await CLToken.deployed();
		let chainlotpublic = await ChainLotPublic.deployed();

		console.log("ChainLotPublic: " + chainlotpublic.address);

		await chainlotpublic.setChainLotAddress(chainlot.address);
		await chainlotpublic.setCLTokenAddress(cltoken.address);
		await chainlot.setChainLotTicketAddress(chainlotticket.address);
		await chainlot.setCLTokenAddress(cltoken.address);
		await chainlot.setChainLotPoolFactoryAddress(factory.address);
		await chainlotticket.setMinter(chainlot.address, true);
		await factory.transferOwnership(chainlot.address);


		for(i=0; i<5; i++) {
			console.log("new pool progress: " + i);
			let r = await chainlot.newPool();
			console.log(JSON.stringify(r.logs))
		}

	}

	
};

/*module.exports = function(deployer, network) {
	if(network == "develop") {
		deployer.deploy(Migrations);
 	   //deployer.deploy(ChainLot, 70, 25, 5, 1, 1e10, 2, [5,1,1e64,5,0,1e14,4,1,5e13,4,0,2.5e12,3,1,1e12,3,0,5e10,2,1,5e10,1,1,2e10,0,1,1e10]);
		//deployer.deploy(ChainLot, 70, 25, 5, 1, 1e16, 10000, [5,1,1e64,5,0,5e21,4,1,5e19,4,0,2.5e18,3,1,1e18,3,0,5e16,2,1,5e16,1,1,2e16,0,1,1e16]);
		//deployer.deploy(ChainLot, 5, 5, 2, 1, 1e10, 2, [2,1,1e64,2,0,1e12,1,1,5e11,0,1,1e10]);
		deployer.deploy(ChainLot, 2, 2, 2, 1, 1e10, 10, [0,1,1e10, 2,1,2e16]);
		deployer.deploy(ChainLotTicket);
		deployer.deploy(CLToken, 100000000000);
		deployer.deploy(ChainLotPoolFactory);
		deployer.deploy(ChainLotPublic);
		//2, 2, 2, 1, 10000000000, 2, [2,1,2000000000000000,0,1,10000000000]

	}
	else if (network == "rinkeby") {
		deployer.deploy(ChainLot, 70, 25, 5, 1, 1e16, 10000, [5,1,1e64,5,0,5e21,4,1,5e19,4,0,2.5e18,3,1,1e18,3,0,5e16,2,1,5e16,1,1,2e16,0,1,1e16]);
		deployer.deploy(ChainLotTicket);
		deployer.deploy(CLToken, 1e12);
		deployer.deploy(ChainLotPoolFactory);
		deployer.deploy(ChainLotPublic);
	}
  
};*/
