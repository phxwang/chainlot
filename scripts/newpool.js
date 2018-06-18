var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");

module.exports = async function(callback) {
	//console.log("from: " + web3.eth.accounts[0]);
	web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0)

	try {
		let chainlot = await ChainLot.deployed();

		for(i=0; i<50; i++) {
			console.log("new pool progress: " + i);
			let r = await chainlot.newPool();
			console.log(JSON.stringify(r.logs))
		}


	} catch(e) {
		console.log(e);
	}
}