var ChainLot = artifacts.require("./ChainLot.sol");


contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		//buyRandom(chainlot, 0, afterBuyRandom)(null);		
	})
})

var buyRandom=function(chainlot, index, thenFunc) {
	return function(r) {
		console.log("buy random tickets, progress: " + (index+1)*10);
		//console.log(JSON.stringify(r));
		if(index < 10)
			chainlot.buyRandom({from:web3.eth.accounts[2], value:1e11, gas:5000000}).then(buyRandom(chainlot, index+1, thenFunc));
		else
			thenFunc(chainlot);
	}
}

var afterBuyRandom=function(chainlot) {
	chainlot.buyTicket([1,1,2], {from:web3.eth.accounts[2], value:2e10}).then(function(r){
		console.log("buy some tickets");
		console.log(JSON.stringify(r));

		chainlot.award({gas:5000000}).then(function(r){
			console.log("award");
			for(log in r.logs) {
				console.log(JSON.stringify(r.logs[log]));	
			}
			
		});
	});
}