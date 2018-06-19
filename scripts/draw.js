var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");

module.exports = async function(callback) {
	console.log("from: " + web3.eth.accounts[0] + ", balance: " 
		+ web3.fromWei(web3.eth.getBalance(web3.eth.accounts[0]), "ether"));
	web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "Z7YFSFD5927v7jW5ig", 0)

	try {
		let chainlot = await ChainLot.deployed();
		let chainlotticket = await ChainLotTicket.deployed();
		let cltoken = await CLToken.deployed();

		for(i=2; i<100; i++) {
			let address = await chainlot.chainlotPools(i);
			if(address == "0x") break;

			let pool = await ChainLotPool.at(address);
			let token = await cltoken.balanceOf(address);
			let prepared = await pool.preparedAwards();
			let currentPoolIndex = await chainlot.currentPoolIndex();
				

			currentBlockNumber = web3.eth.blockNumber;
			let poolBlockNumber = await pool.poolBlockNumber();

			if(token != 0 && !prepared && poolBlockNumber < currentBlockNumber) {
				console.log(["pool ", i, "(", address, ")", ", pool ether: ", 
					web3.fromWei(token, 'ether'), " ETH", ", drawed: ", prepared].join(""));
				
				console.log("prepare awards");
				r = await pool.prepareAwards();
				console.log(JSON.stringify(r.logs));
				
				//TODO: use ticket number to determine match round
				console.log("match awards, progress: " + 100);
				r = await pool.matchAwards(100);
				console.log(JSON.stringify(r.logs));
				
				for(i =0 ; i<8 ; i++) {
					console.log("calculate awards, rule id " + i);
					r = await pool.calculateAwards(i, 100)
					console.log(JSON.stringify(r.logs));
				}

				console.log("split awards");
				r = await pool.splitAward();
				console.log(JSON.stringify(r.logs));


				for(i =0 ; i<8 ; i++) {
					console.log("distribute awards, rule id " + i);
					r = await pool.distributeAwards(i, 100);
					console.log(JSON.stringify(r.logs));
				}

				console.log("send awards");
				r = await pool.sendAwards(100)
				console.log(JSON.stringify(r.logs));

			}

			if(token!=0 && prepared) {
				console.log("transfer unawarded");
				let nextPoolAddress = await chainlot.chainlotPools(currentPoolIndex);
				r = await pool.transferUnawarded(nextPoolAddress);
				console.log(JSON.stringify(r.logs));
			}
		}



	} catch(e) {
		console.log(e);
	}
}