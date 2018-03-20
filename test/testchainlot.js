var ChainLot = artifacts.require("./ChainLot.sol");


contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		console.log(chainlot.address);
		chainlot.buyRandom({from:web3.eth.accounts[2], value:1e11, gas:5000000}).then(function(r){
			console.log("buy random tickets");
			console.log(JSON.stringify(r));

			chainlot.buyTicket([1,2], {from:web3.eth.accounts[2], value:2e10}).then(function(r){
				console.log("buy some tickets");
				console.log(JSON.stringify(r));

				chainlot.award({gas:5000000}).then(function(r){
					console.log("award");
					console.log(JSON.stringify(r));
				});
			});
		});
		
	})
})