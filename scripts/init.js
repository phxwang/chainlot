var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");
var ChainLotToken = artifacts.require("./ChainLotToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");
var AffiliateStorage = artifacts.require("./AffiliateStorage.sol");


module.exports = async function(callback) {
	poolnum = 5;

	let chainlot = await ChainLot.deployed();
	let chainlotticket = await ChainLotTicket.deployed();
	let factory = await ChainLotPoolFactory.deployed();
	let chainlotcoin = await ChainLotCoin.deployed();
	let chainlottoken = await ChainLotToken.deployed();
	let chainlotpublic = await ChainLotPublic.deployed();
	let drawingtool = await DrawingTool.deployed();
	let affiliate = await AffiliateStorage.deployed();

	console.log("ChainLotPublic: " + chainlotpublic.address);

	await chainlotpublic.setChainLotAddress(chainlot.address);
	await chainlot.setChainLotTicketAddress(chainlotticket.address);
	await chainlot.setChainLotCoinAddress(chainlotcoin.address);
	await chainlot.setChainLotTokenAddress(chainlottoken.address);
	await chainlot.setChainLotPoolFactoryAddress(factory.address);
	await chainlot.setAffiliateStorageAddress(affiliate.address);
	await chainlotticket.setMinter(chainlot.address, true);
	await chainlottoken.setMinter(chainlot.address, true);
	await factory.transferOwnership(chainlot.address);
	await drawingtool.init(chainlotticket.address, chainlotcoin.address);

	for(i=0; i<poolnum; i++) {
		console.log("new pool progress: " + i);
		let r = await chainlot.newPool();
		console.log(JSON.stringify(r.logs))
	}
};
