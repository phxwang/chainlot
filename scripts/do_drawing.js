var doDrawing = async function(chainlot, chainlotticket, cltoken, drawingtool, ChainLotPool, web3) {
	let results = await chainlot.retrievePoolInfo();
	console.log("pool token sum: " + web3.fromWei(results[0], 'ether'));
	console.log("pool number: " + results[1]);
	console.log("total token sum: " + web3.fromWei(results[2], 'ether'));
	console.log("current pool count: " + results[3]);

	try {

		for(i=0; i<results[3]; i++) {
			let address = await chainlot.chainlotPools(i);
			if(address == "0x") break;

			let pool = await ChainLotPool.at(address);
			let token = await cltoken.balanceOf(address);
			let stage = await pool.stage();
			let currentPoolIndex = await chainlot.currentPoolIndex();
				

			currentBlockNumber = web3.eth.blockNumber;
			let poolBlockNumber = await pool.poolBlockNumber();

			if(token != 0 && stage < 7 && poolBlockNumber < currentBlockNumber) {
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
							for(i =0 ; i<9 ; i++) {
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
							for(i =0 ; i<9 ; i++) {
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
	catch(e) {
		console.log(e);
	}
}

var showStage = async function(pool) {
	let stage = await pool.stage();
	console.log("stage: " + stage);
	return stage;
}

module.exports = {
	doDrawing : doDrawing
}