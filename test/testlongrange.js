var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");

return;
//a = [70, 25, 5, 1, 1e16, 10000, [5,1,1e64,5,0,5e21,4,1,5e19,4,0,2.5e18,3,1,1e18,3,0,5e16,2,1,5e16,1,1,2e16,0,1,1e16]];
//console.log(a);

contract("ChainLot", async (accounts) => {
	console.log("from: " + web3.eth.accounts[0]);
	
	let chainlot = await ChainLot.deployed();
	let chainlotticket = await ChainLotTicket.deployed();
	let factory = await ChainLotPoolFactory.deployed();
	let cltoken = await CLToken.deployed();
	let chainlotpublic = await ChainLotPublic.deployed();
	let drawingtool = await DrawingTool.deployed();

	await chainlotpublic.setChainLotAddress(chainlot.address);
	await chainlotpublic.setCLTokenAddress(cltoken.address);
	await chainlot.setChainLotTicketAddress(chainlotticket.address);
	await chainlot.setCLTokenAddress(cltoken.address);
	await chainlot.setChainLotPoolFactoryAddress(factory.address);
	await chainlotticket.setMinter(chainlot.address, true);
	await factory.transferOwnership(chainlot.address);
	await drawingtool.init(chainlotticket.address, cltoken.address);

	for(i=0; i<5; i++) {
		console.log("new pool progress: " + i);
		let r = await chainlot.newPool();
		//console.log(JSON.stringify(r.logs))
	}


	for(i=0; i<20000; i++) {
		let id = Math.floor(Math.random()*10);
		console.log(i+" from account: " + id);
		r = await chainlotpublic.buyRandom(13, web3.eth.accounts[(id+1)%10],{from:web3.eth.accounts[id], value:2e6});
		console.log(JSON.stringify(r.receipt.gasUsed));	
	}

	for(pi=0; pi<2; pi++) {
		totalGas = 0;
		let pooladdress = await chainlot.chainlotPools(pi);
		console.log(pi + ": " + pooladdress);
		let pool = await ChainLotPool.at(pooladdress);

		await pool.setDrawingToolAddress(drawingtool.address);

		console.log("prepare awards");
		r = await drawingtool.prepareAwards(pooladdress);
		//console.log(JSON.stringify(r.logs));
		console.log(JSON.stringify(r.receipt.gasUsed));	
		totalGas += Number(r.receipt.gasUsed);

		await showStage(pool);
		
		for(i=0; i<300; i++) {
			console.log("match awards, progress: " + i*100);
			r = await drawingtool.matchAwards(pooladdress, 100);
			console.log(JSON.stringify(r.logs));
			console.log(JSON.stringify(r.receipt.gasUsed));	
			totalGas += Number(r.receipt.gasUsed);
			stage = await showStage(pool);
			if(stage == 2) break;
		}

		
		
		for(i =0 ; i<2 ; i++) {
			console.log("calculate awards, rule id " + i);
			r = await drawingtool.calculateAwards(pooladdress, i, 100)
			//console.log(JSON.stringify(r.logs));
			console.log(JSON.stringify(r.receipt.gasUsed));	
			totalGas += Number(r.receipt.gasUsed);
			await showStage(pool);
		}

		console.log("split awards");
		r = await drawingtool.splitAward(pooladdress);
		//console.log(JSON.stringify(r.logs));
		console.log(JSON.stringify(r.receipt.gasUsed));	
		totalGas += Number(r.receipt.gasUsed);

		await showStage(pool);


		for(i =0 ; i<2; i++) {
			console.log("distribute awards, rule id " + i);
			r = await drawingtool.distributeAwards(pooladdress, i, 100);
			//console.log(JSON.stringify(r.logs));
			console.log(JSON.stringify(r.receipt.gasUsed));	
			totalGas += Number(r.receipt.gasUsed);

			await showStage(pool);
		}

		await showPoolToken(chainlot, cltoken);

		for(i=0; i<100; i++) {
			console.log("send awards: " + i*100);
			r = await drawingtool.sendAwards(pooladdress, 100)
			//console.log(JSON.stringify(r.logs));
			console.log(JSON.stringify(r.receipt.gasUsed));	
			totalGas += Number(r.receipt.gasUsed);
			stage = await showStage(pool);
			if(stage == 6) break;
		}

		
		

		console.log("eth balance of cltoken: " + JSON.stringify(web3.eth.getBalance(cltoken.address)));
		let clbalance = await cltoken.balanceOf(cltoken.address);
		console.log("cltoken balance of cltoken: " + web3.fromWei(clbalance, 'ether'));

		await showStage(pool);
		await showPoolToken(chainlot, cltoken);

		console.log("transfer unawarded");
		let nextPoolAddress = await chainlot.chainlotPools(pi+1);
		r = await drawingtool.transferUnawarded(pooladdress, nextPoolAddress);
		//console.log(JSON.stringify(r.logs));
		console.log(JSON.stringify(r.receipt.gasUsed));	
		totalGas += Number(r.receipt.gasUsed);
		console.log("total Gas: " + totalGas);


		await showStage(pool);

		await showPoolToken(chainlot, cltoken);
		

		let historyCutSum = 0;
		for(i=0; i<web3.eth.accounts.length; i++) {
			account = web3.eth.accounts[i];
			let abalance = await cltoken.balanceOf(account);
			console.log("cltoken balance of account " + account + "("+i+"):  " + web3.fromWei(abalance, 'ether'));

			let tickets = await chainlotticket.ticketsOfOwner(account);
			console.log("tickets of account " + account + "("+i+"):  " + JSON.stringify(tickets));
			let cut = await chainlotpublic.listUserHistoryCut(account, 0, 3, tickets);
			console.log("history cut of account " + account + "("+i+"):  " + JSON.stringify(cut));
			historyCutSum += Number(cut[pi]);
			r = await chainlotpublic.withDrawHistoryCut(0,3,tickets, {from:account});
			//console.log(JSON.stringify(r.logs));
			let cut1 = await chainlotpublic.listUserHistoryCut(account, 0, 3, tickets);
			console.log("after withdraw " + account + "("+i+"):  " + JSON.stringify(cut1));
		}
		console.log("historyCutSum: " + web3.fromWei(historyCutSum, 'ether'));
	}

	let results = await chainlotpublic.retrievePoolInfo();
	console.log("pool token sum: " + web3.fromWei(results[0], 'ether'));
	console.log("pool number: " + results[1]);
	console.log("total token sum: " + web3.fromWei(results[2], 'ether'));

	results = await chainlotpublic.getWinnerList(0, 10);
	console.log(JSON.stringify(results));
})

var showPoolToken = async function(chainlot, cltoken) {
	let poolSize = await chainlot.currentPoolIndex();
	for(i=0; i<=poolSize; i++) {
		let address = await chainlot.chainlotPools(i);
		let balance = await cltoken.balanceOf(address);
		console.log("pool balance of " + address + "[" + i + "]:  " + web3.fromWei(balance, 'ether'));
	};
}

var showStage = async function(pool) {
	let stage = await pool.stage();
	console.log("stage: " + stage);
	return stage;
}




