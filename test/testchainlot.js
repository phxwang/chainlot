var ChainLot = artifacts.require("./ChainLot.sol");


contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		console.log(chainlot.address);
		chainlot.buyTicket([12,23,34,46,55,23], {from:web3.eth.accounts[2], value:2e16}).then(function(r){
			console.log("buy some tickets");
			console.log(JSON.stringify(r));
		});

		chainlot.buyRandom({from:web3.eth.accounts[2], value:3e16}).then(function(r){
			console.log("buy randowm tickets");
			console.log(JSON.stringify(r));
		});

		chainlot.award().then(function(r){
			console.log("awards");
			console.log(JSON.stringify(r));
		});
	})
})