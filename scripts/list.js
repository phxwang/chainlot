var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");

module.exports = async function(callback) {
	try {
		let chainlot = await ChainLot.deployed();
		let chainlotcoin = await ChainLotCoin.deployed();
		//let poolSize = await ChainLot.chainlotPools.length();

		for(i=0; i<100; i++) {
			let address = await chainlot.chainlotPools(i);
			if(address == "0x") break;

			let pool = await ChainLotPool.at(address);
			let token = await chainlotcoin.balanceOf(address);
			let stage = await pool.stage();
			let poolBlockNumber = await pool.poolBlockNumber();
			let historyCut = await pool.historyCut();
			if(token != 0)
				console.log(["pool ", i, "(", address, ")(", poolBlockNumber, "), pool ether: ", 
					web3.fromWei(token, 'ether'), " ETH, historyCut: ", web3.fromWei(historyCut,"ether"), " ETH, stage: ", stage].join(""));
		}


	} catch(e) {
		console.log(e);
	}
}