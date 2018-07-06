var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
return;
contract("ChainLot", async (accounts) => {
	console.log("from: " + web3.eth.accounts[0]);
	
	let chainlot = await ChainLot.deployed();
	let chainlotticket = await ChainLotTicket.deployed();
	let factory = await ChainLotPoolFactory.deployed();
	let chainlotcoin = await ChainLotCoin.deployed();
	let chainlotpublic = await ChainLotPublic.deployed();
	await chainlotpublic.setChainLotAddress(chainlot.address);
	await chainlotpublic.setChainLotCoinAddress(chainlotcoin.address);
	await chainlot.setChainLotTicketAddress(chainlotticket.address);
	await chainlot.setChainLotCoinAddress(chainlotcoin.address);
	await chainlot.setChainLotPoolFactoryAddress(factory.address);
	await chainlotticket.setMinter(chainlot.address, true);
	await factory.transferOwnership(chainlot.address);

	let r = await chainlot.newPool();
	let address = await chainlot.chainlotPools(0);
	let pool = await ChainLotPool.at(address);

	for(i=0;i<1000;i++) {
			r = await pool.genRandomNumbers(web3.eth.blockNumber-1, 8);
			console.log(JSON.stringify(r.logs));
			await web3.eth.sendTransaction({from:accounts[0], to:accounts[1], value:100});
	}
});