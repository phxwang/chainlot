var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var ChainLotCoin = artifacts.require("./ChainLotCoin.sol");
var ChainLotToken = artifacts.require("./ChainLotToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");
var ChainLotPool = artifacts.require("./ChainLotPool.sol");
var ChainLotPublic = artifacts.require("./ChainLotPublic.sol");
var DrawingTool = artifacts.require("./DrawingTool.sol");

//a = [70, 25, 5, 1, 1e16, 10000, [5,1,1e64,5,0,5e21,4,1,5e19,4,0,2.5e18,3,1,1e18,3,0,5e16,2,1,5e16,1,1,2e16,0,1,1e16]];
//console.log(a);
//return;

contract("ChainLot", async (accounts) => {
	console.log("from: " + web3.eth.accounts[0]);
	
	let chainlot = await ChainLot.deployed();
	let chainlotticket = await ChainLotTicket.deployed();
	let factory = await ChainLotPoolFactory.deployed();
	let chainlotcoin = await ChainLotCoin.deployed();
	let chainlottoken = await ChainLotToken.deployed();
	let chainlotpublic = await ChainLotPublic.deployed();
	let drawingtool = await DrawingTool.deployed();

	let ad = await chainlotpublic.owner();
	console.log(ad);
	await chainlotpublic.setChainLotAddress(chainlot.address);
	await chainlot.setChainLotTicketAddress(chainlotticket.address);
	await chainlot.setChainLotCoinAddress(chainlotcoin.address);
	await chainlot.setChainLotTokenAddress(chainlottoken.address);
	await chainlot.setChainLotPoolFactoryAddress(factory.address);
	await chainlotticket.setMinter(chainlot.address, true);
	await chainlottoken.setMinter(chainlot.address, true);
	await factory.transferOwnership(chainlot.address);
	await drawingtool.init(chainlotticket.address, chainlotcoin.address);

	for(i=0; i<5; i++) {
		console.log("new pool progress: " + i);
		let r = await chainlot.newPool();
		//console.log(JSON.stringify(r.logs))
	}

	//r = await chainlotpublic.getWinnerList(0, 10);
	//console.log(JSON.stringify(r));

	//return;


	r = await chainlotcoin.sendTransaction({from:web3.eth.accounts[5], value:5e11});
	//console.log(JSON.stringify(r));

	//r = await chainlotcoin.approveAndCall(chainlotpublic.address, 1e11, "0x020101", {from:web3.eth.accounts[5]});
	//console.log(JSON.stringify(r.receipt.gasUsed));	
	//console.log(JSON.stringify(r.logs));

	cl = await chainlotpublic.chainlot();
	//console.log("cl: " + cl);

	r = await chainlotpublic.sendTransaction({from:web3.eth.accounts[5], value:2e11});
	//r = await chainlotpublic.buyRandom(13, web3.eth.accounts[2],{from:web3.eth.accounts[1], value:5e11});
	console.log(JSON.stringify(r.logs));

	await showAccountToken(chainlottoken);
	await showPoolCoin(chainlot, chainlotcoin);

	for(i=0; i<20; i++) {
		let id = Math.floor(Math.random()*10);
		console.log("from account: " + id);
		r = await chainlotpublic.buyRandom(13, web3.eth.accounts[(id+1)%10],{from:web3.eth.accounts[id], value:5e12});
		console.log(JSON.stringify(r.receipt.gasUsed));	

		let price = await chainlottoken.getPrice();
		console.log("price of clt: " + web3.fromWei(price, "ether"));

		let reedemPrice = await chainlottoken.currentReedemPrice();
		console.log("reedemPrice of clt: " + web3.fromWei(reedemPrice, "ether"));
	}

	//return;

	for(pi=1; pi<2; pi++) {
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
		
		for(i=0; i<50; i++) {
			console.log("match awards, progress: " + i*25);
			r = await drawingtool.matchAwards(pooladdress, 25);
			//console.log(JSON.stringify(r.logs));
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
		console.log(JSON.stringify(r.logs));
		console.log(JSON.stringify(r.receipt.gasUsed));	
		totalGas += Number(r.receipt.gasUsed);

		await showStage(pool);


		for(i =0 ; i<2 ; i++) {
			console.log("distribute awards, rule id " + i);
			r = await drawingtool.distributeAwards(pooladdress, i, 100);
			//console.log(JSON.stringify(r.logs));
			console.log(JSON.stringify(r.receipt.gasUsed));	
			totalGas += Number(r.receipt.gasUsed);

			await showStage(pool);
		}

		await showPoolCoin(chainlot, chainlotcoin);

		for(i=0; i<2; i++) {
			console.log("send awards: " + i*5);
			r = await drawingtool.sendAwards(pooladdress, 100)
			//console.log(JSON.stringify(r.logs));
			console.log(JSON.stringify(r.receipt.gasUsed));	
			totalGas += Number(r.receipt.gasUsed);
			stage = await showStage(pool);
			if(stage == 6) break;
		}

		
		

		console.log("eth balance of chainlotcoin: " + JSON.stringify(web3.eth.getBalance(chainlotcoin.address)));
		let clbalance = await chainlotcoin.balanceOf(chainlotcoin.address);
		console.log("chainlotcoin balance of chainlotcoin: " + web3.fromWei(clbalance, 'ether'));

		await showStage(pool);
		await showPoolCoin(chainlot, chainlotcoin);

		console.log("transfer unawarded");
		let nextPoolAddress = await chainlot.chainlotPools(pi+1);
		r = await drawingtool.transferUnawarded(pooladdress, nextPoolAddress);
		//console.log(JSON.stringify(r.logs));
		console.log(JSON.stringify(r.receipt.gasUsed));	
		totalGas += Number(r.receipt.gasUsed);
		console.log("total Gas: " + totalGas);


		await showStage(pool);

		await showPoolCoin(chainlot, chainlotcoin);
		await showAccountCoin(chainlotcoin);
		await showAccountToken(chainlottoken);
		
	}

	let results = await chainlotpublic.retrievePoolInfo();
	console.log("pool token sum: " + web3.fromWei(results[0], 'ether'));
	console.log("pool number: " + results[1]);
	console.log("total token sum: " + web3.fromWei(results[2], 'ether'));

	results = await chainlotpublic.getWinnerList(0, 10);
	//console.log(JSON.stringify(results));
})

var showPoolCoin = async function(chainlot, chainlotcoin) {
	let poolSize = await chainlot.currentPoolIndex();
	for(i=0; i<=poolSize; i++) {
		let address = await chainlot.chainlotPools(i);
		let balance = await chainlotcoin.balanceOf(address);
		console.log("pool balance of " + address + "[" + i + "]:  " + web3.fromWei(balance, 'ether'));
	};
}

var showAccountToken = async function(chainlottoken) {
	for(i=0;i<web3.eth.accounts.length;i++) {
		let tb = await chainlottoken.balanceOf(web3.eth.accounts[i]);
		console.log("token of " + web3.eth.accounts[i] + " : " + web3.fromWei(tb, "ether"));
	}
	let balance = await web3.eth.getBalance(chainlottoken.address);
	console.log("balance of clt: " + web3.fromWei(balance, "ether"));

	let price = await chainlottoken.getPrice();
	console.log("price of clt: " + web3.fromWei(price, "ether"));

	let reedemPrice = await chainlottoken.currentReedemPrice();
	console.log("reedemPrice of clt: " + web3.fromWei(reedemPrice, "ether"));
}

var showAccountCoin = async function(chainlotcoin) {
	for(i=0;i<web3.eth.accounts.length;i++) {
		let tb = await chainlotcoin.balanceOf(web3.eth.accounts[i]);
		console.log("coin of " + web3.eth.accounts[i] + " : " + web3.fromWei(tb, "ether"));
	}
	let balance = await web3.eth.getBalance(chainlotcoin.address);
	console.log("balance of clc: " + web3.fromWei(balance, "ether"));
}

var showStage = async function(pool) {
	let stage = await pool.stage();
	console.log("stage: " + stage);
	return stage;
}




