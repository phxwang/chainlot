var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");

module.exports = async function(callback) {
	try {
		let chainlot = await ChainLot.deployed();
		let cltoken = await CLToken.deployed();
		//let poolSize = await ChainLot.chainlotPools.length();

		for(i=0; i<100; i++) {
			let address = await chainlot.chainlotPools(i);
			if(address == "0x") break;

			let pool = await ChainLotPool.at(address);
			let token = await cltoken.balanceOf(address);
			let prepared = await pool.preparedAwards();
			let poolBlockNumber = await pool.poolBlockNumber();
			if(token != 0)
				console.log(["pool ", i, "(", address, ")(", poolBlockNumber, "), pool ether: ", 
					web3.fromWei(token, 'ether'), " ETH", ", drawed: ", prepared].join(""));
		}


	} catch(e) {
		console.log(e);
	}
}