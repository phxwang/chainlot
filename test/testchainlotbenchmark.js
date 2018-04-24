var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");

var cltoken;
contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		ChainLotTicket.deployed().then(function(chainlotticket) {
			ChainLotPoolFactory.deployed().then(function(factory) {
				CLToken.deployed().then(function(_cltoken) {
					cltoken = _cltoken;
					chainlot.setChainLotTicketAddress(chainlotticket.address).then(function(r) {
						//console.log("set ticket " + JSON.stringify(r));	
						chainlot.setCLTokenAddress(cltoken.address).then(function(r) {
							//console.log("set cltoken " + JSON.stringify(r));	
							chainlot.setChainLotPoolFactoryAddress(factory.address).then(function(r) {
								//console.log("set factory " + JSON.stringify(r));		
								chainlotticket.setMinter(chainlot.address, true).then(function(r){
									factory.transferOwnership(chainlot.address).then(function(r) {
										//console.log("set minter " + JSON.stringify(r));	
										/*cltoken.sendTransaction({from:web3.eth.accounts[0], value:1e11, gas:5000000}).then(function(r) {
											cltoken.balanceOf(web3.eth.accounts[0]).then(function(r) {
												console.log(JSON.stringify(r));
											})
										})*/
										//console.log(JSON.stringify(r.logs));	
										chainlot.newPool({gas:5000000}).then((r)=>{
											console.log(JSON.stringify(r.logs));	
											buyRandom(chainlot, 0, afterBuyRandom)(null);
											/*chainlot.buyRandom(web3.eth.accounts[2],{from:web3.eth.accounts[1],value:1e11, gas:5000000}).then(function(r) {
												console.log(JSON.stringify(r.logs));
											});*/
										});

									});
									
								});

							});
							
						});
					});
				});
			});			
		});		
	});
})

var buyRandom=function(chainlot, index, thenFunc) {
	return function(r) {
		if(index > 0) {
			console.log("buy random, progress: " + index*10);
			console.log(JSON.stringify(r.logs));
		}
		if(index < 10) {
			id = Math.floor(Math.random()*10);
			console.log("from account: " + id);
			chainlot.buyRandom(web3.eth.accounts[(id+1)%10],{from:web3.eth.accounts[id], value:1e11, gas:5000000}).then(buyRandom(chainlot, index+1, thenFunc));
		}
		else
			thenFunc(chainlot);
	}
}

var matchAwards=function(chainlot, index, thenFunc) {
	return function(r) {
		if(index > 0) {
			console.log("match awards, progress: " + index*10);
			console.log(JSON.stringify(r.logs));
		}	
		if(index < 2) {
			chainlot.matchAwards(100, {gas:5000000}).then(matchAwards(chainlot, index+1, thenFunc));
		}
		else {
			thenFunc(chainlot);
		}
	}
}

var addBlockNumber =function(chainlot, index, thenFunc) {
	return function(r) {
		if(index > 0) {
			console.log("add block number, progress: " + index);
		}	

		if(index < 50) {
			web3.eth.sendTransaction({from:web3.eth.accounts[0], 
				to:web3.eth.accounts[1], value:1e2}, addBlockNumber(chainlot, index+1, thenFunc));
		}
		else {
			thenFunc(chainlot);
		}
	}
}

var afterAddBlockNumber=function(chainlot) {
	chainlot.prepareAwards({gas:5000000}).then(function(r){
			console.log("prepare awards");
			console.log(JSON.stringify(r.logs));
			matchAwards(chainlot, 0, afterMatchAwards)(null);
			
	});
}

var afterBuyRandom=function(chainlot) {
	chainlot.buyTicket("0x010202", web3.eth.accounts[0], {from:web3.eth.accounts[Math.floor(Math.random()*10)], value:2e11}).then(function(r){
		console.log("buy some tickets");
		console.log(JSON.stringify(r.logs));

		/*chainlot.listAllPool().then(function(r){
			console.log(JSON.stringify(r));
		})*/
		addBlockNumber(chainlot, 0, afterAddBlockNumber)(null);
	});
}

var afterMatchAwards=function(chainlot) {
	chainlot.calculateAwards({gas:5000000}).then(function(r){
		console.log("calculate awards");
		console.log(JSON.stringify(r.logs));
		chainlot.distributeAwards({gas:5000000}).then(function(r){
			console.log("distribute awards");
			console.log(JSON.stringify(r.logs));
			chainlot.sendAwards({gas:5000000}).then(function(r){
				console.log("send awards");
				console.log(JSON.stringify(r.logs));

				console.log("eth balance of cltoken: " + JSON.stringify(web3.eth.getBalance(cltoken.address)));
				cltoken.balanceOf(cltoken.address).then(function(r) {
					console.log("cltoken balance of cltoken: " + JSON.stringify(r));
				})
				//console.log(JSON.stringify(web3.eth.getBalance(chainlot.address)));
			});
		});
	});
}