var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");
var ChainLotPoolFactory = artifacts.require("./ChainLotPoolFactory.sol");

var cltoken;
var chainlotticket;
contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		ChainLotTicket.deployed().then(function(_chainlotticket) {
			chainlotticket = _chainlotticket;
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

										newPool(chainlot, 0, afterNewPool)(null);
										/*chainlot.newPool({gas:5000000}).then((r)=>{
											console.log(JSON.stringify(r.logs));	
											buyRandom(chainlot, 0, afterBuyRandom)(null);
											chainlot.buyRandom(web3.eth.accounts[2],{from:web3.eth.accounts[1],value:1e11, gas:5000000}).then(function(r) {
												console.log(JSON.stringify(r.logs));
											});
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
})
var newPool=function(chainlot, index, thenFunc) {
	return function(r) {
		if(index > 0) {
			console.log("new pool progress: " + index);
			console.log(JSON.stringify(r.logs));
		}
		if(index < 5) {
			chainlot.newPool({gas:5000000}).then(newPool(chainlot, index+1, thenFunc));
		}
		else
			thenFunc(chainlot);
	}
}

var afterNewPool=function(chainlot) {
	buyRandom(chainlot, 0, afterBuyRandom)(null);
}

var buyRandom=function(chainlot, index, thenFunc) {
	return function(r) {
		if(index > 0) {
			console.log("buy random, progress: " + index*10);
			console.log(JSON.stringify(r.logs));
		}
		if(index < 20) {
			id = Math.floor(Math.random()*10);
			console.log("from account: " + id);
			chainlot.buyRandom(web3.eth.accounts[(id+1)%10],{from:web3.eth.accounts[id], value:1e11, gas:5000000}).then(buyRandom(chainlot, index+1, thenFunc));
		}
		else
			thenFunc(chainlot);
	}
}

var afterBuyRandom=function(chainlot) {
	chainlot.buyTicket("0x010202", web3.eth.accounts[0], {from:web3.eth.accounts[Math.floor(Math.random()*10)], value:2e11}).then(function(r){
		console.log("buy some tickets");
		console.log(JSON.stringify(r.logs));

		/*chainlot.listAllPool().then(function(r){
			console.log(JSON.stringify(r));
		})*/
		addBlockNumber(chainlot, 0, afterAddBlockNumber)(null);
		listPool(chainlot);
	});
}

var addBlockNumber =function(chainlot, index, thenFunc) {
	return function(r) {
		if(index > 0) {
			console.log("add block number, progress: " + index);
		}	

		if(index < 0) {
			web3.eth.sendTransaction({from:web3.eth.accounts[0], 
				to:web3.eth.accounts[1], value:1e2}, addBlockNumber(chainlot, index+1, thenFunc));
		}
		else {
			thenFunc(chainlot);
		}
	}
}

var afterAddBlockNumber=function(chainlot) {
	chainlot.prepareAwards(1, {gas:5000000}).then(function(r){
			console.log("prepare awards");
			console.log(JSON.stringify(r.logs));
			matchAwards(chainlot, 0, afterMatchAwards)(null);
			
	});
}



var matchAwards=function(chainlot, index, thenFunc) {
	return function(r) {
		if(index > 0) {
			console.log("match awards, progress: " + index*10);
			console.log(JSON.stringify(r.logs));
		}	
		if(index < 2) {
			chainlot.matchAwards(1, 100, {gas:5000000}).then(matchAwards(chainlot, index+1, thenFunc));
		}
		else {
			thenFunc(chainlot);
		}
	}
}

var listPool=function(chainlot) {
	chainlot.currentPoolIndex().then(function(r) {
		for(i=0; i<=r; i++) {
			chainlot.chainlotPools(i).then(function(index) {
				return function(r) {
					//console.log("pool: " + r);
					cltoken.balanceOf(r).then(function(account, index1) {
						return function(r) {
							console.log("pool balance of " + account + "[" + index1 + "]:  " + JSON.stringify(r));
						}
					}(r, index));

				}
			}(i));
			
		}
	});
}

var afterMatchAwards=function(chainlot) {
	chainlot.calculateAwards(1, {gas:5000000}).then(function(r){
		console.log("calculate awards");
		console.log(JSON.stringify(r.logs));
		chainlot.distributeAwards(1, {gas:5000000}).then(function(r){
			console.log("distribute awards");
			console.log(JSON.stringify(r.logs));
			chainlot.sendAwards(1, {gas:5000000}).then(function(r){
				console.log("send awards");
				console.log(JSON.stringify(r.logs));


				console.log("eth balance of cltoken: " + JSON.stringify(web3.eth.getBalance(cltoken.address)));
				cltoken.balanceOf(cltoken.address).then(function(r) {
					console.log("cltoken balance of cltoken: " + JSON.stringify(r));

					//listPool(chainlot);

					chainlot.transferUnawarded(1, 2, {gas:5000000}).then(function(r){
						console.log("transfer unawarded");
						console.log(JSON.stringify(r.logs));
						listPool(chainlot);
					});
					
				})
				//console.log(JSON.stringify(web3.eth.getBalance(chainlot.address)));
				/*for(i=0; i<web3.eth.accounts.length; i++) {
					cltoken.balanceOf(web3.eth.accounts[i]).then(function(account) {
						return function(r) {
							console.log("cltoken balance of account " + account + ":  " + JSON.stringify(r));
						}
					}(web3.eth.accounts[i]));

					chainlotticket.ticketsOfOwner(web3.eth.accounts[i]).then(function(account){
						return function(r) {
							if(r.length > 0) {
								console.log("tickets of account " + account + ":  " + JSON.stringify(r));
								//console.log(r);
								chainlot.listUserHistoryCut(account, 0, 3, r).then(function(account1) {
									return function(r) {
										console.log("history cut of account " + account1 + ":  " + JSON.stringify(r));
									}
								}(account));
							}
							
						}
					}(web3.eth.accounts[i]));
				}*/

			});
		});
	});
}



