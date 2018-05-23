var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");

contract("ChainLot", async (accounts) => {

	let chainlot = await ChainLot.deployed();
	let chainlotticket = await ChainLotTicket.deployed();
	let factory = await ChainLotPoolFactory.deployed();
	let cltoken = await CLToken.deployed();
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

	for(i=0; i<20; i++) {
		let id = Math.floor(Math.random()*10);
		console.log("from account: " + id);
		r = await chainlot.buyRandom(web3.eth.accounts[(id+1)%10],{from:web3.eth.accounts[id], value:1e11});
		//console.log(JSON.stringify(r.logs));	
	}

	for(pi=0; pi<2; pi++) {
		let address = await chainlot.chainlotPools(pi);
		console.log(pi + ": " + address);
		let pool = await ChainLotPool.at(address);

		console.log("prepare awards");
		r = await pool.prepareAwards();
		console.log(JSON.stringify(r.logs));
		
		console.log("match awards, progress: " + i*100);
		r = await pool.matchAwards(100);
		console.log(JSON.stringify(r.logs));
		
		for(i =0 ; i<2 ; i++) {
			console.log("calculate awards, rule id " + i);
			r = await pool.calculateAwards(i, 100)
			console.log(JSON.stringify(r.logs));
		}

		console.log("split awards");
		r = await pool.splitAward();
		console.log(JSON.stringify(r.logs));


		for(i =0 ; i<2 ; i++) {
			console.log("distribute awards, rule id " + i);
			r = await pool.distributeAwards(i, 100);
			console.log(JSON.stringify(r.logs));
		}

		console.log("send awards");
		r = await pool.sendAwards(100)
		console.log(JSON.stringify(r.logs));

		console.log("eth balance of cltoken: " + JSON.stringify(web3.eth.getBalance(cltoken.address)));
		let clbalance = await cltoken.balanceOf(cltoken.address);
		console.log("cltoken balance of cltoken: " + JSON.stringify(clbalance));

		let poolSize = await chainlot.currentPoolIndex();
		for(i=0; i<=poolSize; i++) {
			let address = await chainlot.chainlotPools(i);
			let balance = await cltoken.balanceOf(address);
			console.log("pool balance of " + address + "[" + i + "]:  " + JSON.stringify(balance));
		};

		console.log("transfer unawarded");
		let nextPoolAddress = await chainlot.chainlotPools(pi+1);
		r = await pool.transferUnawarded(nextPoolAddress);
		console.log(JSON.stringify(r.logs));

		for(i=0; i<=poolSize; i++) {
			let address = await chainlot.chainlotPools(i);
			let balance = await cltoken.balanceOf(address);
			console.log("pool balance of " + address + "[" + i + "]:  " + JSON.stringify(balance));
		};

		for(i=0; i<web3.eth.accounts.length; i++) {
			account = web3.eth.accounts[i];
			let abalance = await cltoken.balanceOf(account);
			console.log("cltoken balance of account " + account + "("+i+"):  " + JSON.stringify(abalance));

			let tickets = await chainlotticket.ticketsOfOwner(account);
			console.log("tickets of account " + account + "("+i+"):  " + JSON.stringify(tickets));
			let cut = await chainlot.listUserHistoryCut(account, 0, 3, tickets);
			console.log("history cut of account " + account + "("+i+"):  " + JSON.stringify(cut));
		}
	}	

})




