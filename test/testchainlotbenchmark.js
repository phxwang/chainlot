var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");

var cltoken;
contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		ChainLotTicket.deployed().then(function(chainlotticket) {
			CLToken.deployed().then(function(_cltoken) {
				cltoken = _cltoken;
				chainlot.setChainLotTicketAddress(chainlotticket.address).then(function(r) {
					chainlot.setCLTokenAddress(cltoken.address).then(function(r) {
						chainlotticket.transferOwnership(chainlot.address).then(function(r){
							/*cltoken.sendTransaction({from:web3.eth.accounts[0], value:1e11, gas:5000000}).then(function(r) {
								cltoken.balanceOf(web3.eth.accounts[0]).then(function(r) {
									console.log(JSON.stringify(r));
								})
							})*/
							buyRandom(chainlot, 0, afterBuyRandom)(null);
							/*chainlot.buyRandom({value:1e11, gas:500000}).then(function(r) {
								console.log(JSON.stringify(r));
								cltoken.balanceOf(chainlot.address).then(function(r) {
									console.log(JSON.stringify(r));
								})
							});*/
						});
					});
				});
			});			
		});		
	});
})

var buyRandom=function(chainlot, index, thenFunc) {
	return function(r) {
		console.log("buy random tickets, progress: " + (index+1)*10);
		console.log(JSON.stringify(r));
		if(index < 10) {
			id = Math.floor(Math.random()*10);
			console.log("from account: " + id);
			chainlot.buyRandom({from:web3.eth.accounts[id], value:1e11, gas:5000000}).then(buyRandom(chainlot, index+1, thenFunc));
		}
		else
			thenFunc(chainlot);
	}
}

var afterBuyRandom=function(chainlot) {
	chainlot.buyTicket([1,1,2], {from:web3.eth.accounts[Math.floor(Math.random()*10)], value:2e11}).then(function(r){
		console.log("buy some tickets");
		console.log(JSON.stringify(r));

		chainlot.award({gas:5000000}).then(function(r){
			console.log("award");
			for(log in r.logs) {
				console.log(JSON.stringify(r.logs[log]));	
			}
			console.log("eth balance of cltoken: " + JSON.stringify(web3.eth.getBalance(cltoken.address)));
			cltoken.balanceOf(cltoken.address).then(function(r) {
				console.log("cltoken balance of cltoken: " + JSON.stringify(r));
			})
			//console.log(JSON.stringify(web3.eth.getBalance(chainlot.address)));
		});
	});
}