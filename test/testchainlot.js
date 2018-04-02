var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");


/*contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		ChainLotToken.deployed().then(function(chainlottoken) {
			chainlot.setChainLotTokenAddress(chainlottoken.address).then(function(r) {
				chainlottoken.transferOwnership(chainlot.address).then(function(r){
					console.log("buy random tickets");
					chainlot.buyRandom({from:web3.eth.accounts[2], value:1e11, gas:5000000}).then(function(r){
						for(log in r.logs) {
									console.log(JSON.stringify(r.logs[log]));	
						}

						console.log("buy some tickets");
						chainlot.buyTicket([1,1,2], {from:web3.eth.accounts[2], value:2e10}).then(function(r){
							for(log in r.logs) {
									console.log(JSON.stringify(r.logs[log]));	
							}

							console.log("award");
							chainlot.award({gas:5000000}).then(function(r){
								for(log in r.logs) {
									console.log(JSON.stringify(r.logs[log]));	
								}
								
							});
						});
					});
				});
			});			
		});
		
	})
})*/