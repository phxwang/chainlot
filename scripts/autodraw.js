var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");

var doDrawing = require("./do_drawing.js");
console.log(doDrawing);

module.exports = async function(callback) {
	console.log("from: " + web3.eth.accounts[0] + ", balance: " 
		+ web3.fromWei(web3.eth.getBalance(web3.eth.accounts[0]), "ether"));
	web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0)

	try {
		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let chainlotcoin = await ChainLotCoin.deployed();
		let drawingtool = await DrawingTool.deployed();

		i = 0;
		while(i < 10000) {
			
			block = web3.eth.blockNumber
			console.log(block);
			if(block % 100 == 0) {
				//new pool
				console.log("new pool");
				let r = await chainlot.newPool();
				console.log(JSON.stringify(r.logs))

				//buy one ticket
				console.log("check and switch pool");
				r = await chainlot.checkAndSwitchPool();
				console.log(JSON.stringify(r.logs))
				
				//draw last pool
				console.log("do drawing");
				await doDrawing.doDrawing(chainlot, chainlotticket, chainlotcoin, drawingtool, ChainLotPool, web3);
			}
			await sleep(10000);
	    	i++;
    	}

	} catch(e) {
		console.log(e);
	}
}

var sleep = async function(ms) {
	return new Promise(resolve => setTimeout(resolve, ms))
}