var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");

var doDrawing = require("./do_drawing.js");

module.exports = async function(callback) {
	console.log("from: " + web3.eth.accounts[0] + ", balance: " 
		+ web3.fromWei(web3.eth.getBalance(web3.eth.accounts[0]), "ether"));
	web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0)

	try {
		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let chainlotcoin = await ChainLotCoin.deployed();
		let drawingtool = await DrawingTool.deployed();

		console.log(drawingtool.address);

		//doDrawing(chainlot, chainlotticket, chainlotcoin, drawingtool);
		await doDrawing.doDrawing(chainlot, chainlotticket, chainlotcoin, drawingtool, ChainLotPool, web3);

	} catch(e) {
		console.log(e);
	}
}

/*var doDrawing = async function(chainlot, chainlotticket, chainlotcoin, drawingtool) {
	for(i=0; i<100; i++) {
			let address = await chainlot.chainlotPools(i);
			if(address == "0x") break;

			let pool = await ChainLotPool.at(address);
			let token = await chainlotcoin.balanceOf(address);
			let stage = await pool.stage();
			let currentPoolIndex = await chainlot.currentPoolIndex();
				

			currentBlockNumber = web3.eth.blockNumber;
			let poolBlockNumber = await pool.poolBlockNumber();

			if(token != 0 && stage < 8 && poolBlockNumber < currentBlockNumber) {
				console.log(["pool ", i, "(", address, ")", ", pool ether: ", 
					web3.fromWei(token, 'ether'), " ETH", ", stage: ", stage].join(""));

				while(stage < 7) {
					switch(parseInt(stage)) {
						case 0:
							console.log("prepare awards");
							r = await drawingtool.prepareAwards(address);
							console.log(JSON.stringify(r.logs));
							break;
						case 1:
							ticketCount = await pool.getAllTicketsCount();
							console.log("match awards, ticketCount: " + ticketCount);
							r = await drawingtool.matchAwards(address, ticketCount);
							console.log(JSON.stringify(r.logs));
							break;
						case 2:
							for(i =0 ; i<5 ; i++) {
								console.log("calculate awards, rule id " + i);
								r = await drawingtool.calculateAwards(address, i, 100);
								console.log(JSON.stringify(r.logs));
							}
							break;
						case 3:
							console.log("split awards");
							r = await drawingtool.splitAward(address);
							console.log(JSON.stringify(r.logs));
							break;
						case 4:
							for(i =0 ; i<5 ; i++) {
								console.log("distribute awards, rule id " + i);
								r = await drawingtool.distributeAwards(address, i, 100);
								console.log(JSON.stringify(r.logs));
							}
							break;
						case 5:
							console.log("send awards");
							r = await drawingtool.sendAwards(address, 100)
							console.log(JSON.stringify(r.logs));
							break;
						case 6:
							console.log("transfer unawarded");
							let nextPoolAddress = await chainlot.chainlotPools(currentPoolIndex);
							r = await drawingtool.transferUnawarded(address, nextPoolAddress);
							console.log(JSON.stringify(r.logs));
							break;
						default:
							break;
					}
					stage = await showStage(pool);
				}
	
			}

			if(token!=0 && stage > 0) {
				
			}
		}
}

var showStage = async function(pool) {
	let stage = await pool.stage();
	console.log("stage: " + stage);
	return stage;
}*/