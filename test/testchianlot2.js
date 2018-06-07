var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");

//a = [70, 25, 5, 1, 1e16, 10000, [5,1,1e64,5,0,5e21,4,1,5e19,4,0,2.5e18,3,1,1e18,3,0,5e16,2,1,5e16,1,1,2e16,0,1,1e16]];
//console.log(a);
//return;

contract("ChainLot", async (accounts) => {
	console.log("from: " + web3.eth.accounts[0]);
	
	let chainlot = await ChainLot.deployed();
	let chainlotticket = await ChainLotTicket.deployed();
	let factory = await ChainLotPoolFactory.deployed();
	let cltoken = await CLToken.deployed();
	let chainlotpublic = await ChainLotPublic.deployed();
	await chainlotpublic.setChainLotAddress(chainlot.address);
	await chainlotpublic.setCLTokenAddress(cltoken.address);
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

	r = await cltoken.sendTransaction({from:web3.eth.accounts[5], value:5e11});
	console.log(JSON.stringify(r.logs));

	r = await cltoken.approveAndCall(chainlotpublic.address, 1e11, "0x020101", {from:web3.eth.accounts[5]});
	console.log(JSON.stringify(r.logs));

	cl = await chainlotpublic.chainlot();
	console.log("cl: " + cl);

	r = await chainlotpublic.sendTransaction({from:web3.eth.accounts[5], value:2e11});
	console.log(JSON.stringify(r.logs));

	r = await chainlotticket.ticketsOfOwner(web3.eth.accounts[5]);
	console.log("tickets: " + r);

	for(i=0; i<20; i++) {
		let id = Math.floor(Math.random()*10);
		console.log("from account: " + id);
		r = await chainlotpublic.buyRandom(web3.eth.accounts[(id+1)%10],{from:web3.eth.accounts[id], value:1e11});
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
		console.log("cltoken balance of cltoken: " + web3.fromWei(clbalance, 'ether'));

		let poolSize = await chainlot.currentPoolIndex();
		for(i=0; i<=poolSize; i++) {
			let address = await chainlot.chainlotPools(i);
			let balance = await cltoken.balanceOf(address);
			console.log("pool balance of " + address + "[" + i + "]:  " + web3.fromWei(balance, 'ether'));
		};

		console.log("transfer unawarded");
		let nextPoolAddress = await chainlot.chainlotPools(pi+1);
		r = await pool.transferUnawarded(nextPoolAddress);
		console.log(JSON.stringify(r.logs));

		for(i=0; i<=poolSize; i++) {
			let address = await chainlot.chainlotPools(i);
			let balance = await cltoken.balanceOf(address);
			console.log("pool balance of " + address + "[" + i + "]:  " + web3.fromWei(balance, 'ether'));
		};

		let historyCutSum = 0;
		for(i=0; i<web3.eth.accounts.length; i++) {
			account = web3.eth.accounts[i];
			let abalance = await cltoken.balanceOf(account);
			console.log("cltoken balance of account " + account + "("+i+"):  " + web3.fromWei(abalance, 'ether'));

			let tickets = await chainlotticket.ticketsOfOwner(account);
			console.log("tickets of account " + account + "("+i+"):  " + JSON.stringify(tickets));
			let cut = await chainlot.listUserHistoryCut(account, 0, 3, tickets);
			console.log("history cut of account " + account + "("+i+"):  " + JSON.stringify(cut));
			historyCutSum += Number(cut[pi]);
		}
		console.log(web3.fromWei(historyCutSum, 'ether'));
	}	

	let totalTokenSum = await chainlot.tokenSum();
	console.log("total token sum: " + web3.fromWei(totalTokenSum, 'ether'));

})




