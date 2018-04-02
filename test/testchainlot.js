var ChainLot = artifacts.require("./ChainLot.sol");
var ChainLotTicket = artifacts.require("./ChainLotTicket.sol");
var CLToken = artifacts.require("./CLToken.sol");


contract("ChainLot", function(accounts){
	ChainLot.deployed().then(function(chainlot) {
		ChainLotTicket.deployed().then(function(chainlotticket) {
			CLToken.deployed().then(function(cltoken) {
				console.log("set chainlot ticket ");
				chainlot.setChainLotTicketAddress(chainlotticket.address).then(function(r) {
					console.log("set cl token");
					chainlot.setCLTokenAddress(cltoken.address).then(function(r) {
						console.log("transferOwnership ");
						chainlotticket.transferOwnership(chainlot.address).then(function(r){
							console.log("buy random tickets");
							chainlot.buyRandom({from:web3.eth.accounts[2], value:1e11, gas:5000000}).then(function(r){
								for(log in r.logs) {
									console.log(JSON.stringify(r.logs[log]));	
								}
								chainlotticket.ticketsOfOwner(web3.eth.accounts[2]).then((r)=>{
									console.log(JSON.stringify(r));
								})

								cltoken.sendTransaction({from:web3.eth.accounts[4], value:5e11, gas:5000000}).then(function(r) {
									console.log("buy with token");
									cltoken.approveAndCall(chainlot.address, 1e11, "0x020101", {from:web3.eth.accounts[4]}).then(function(r) {
										console.log(JSON.stringify(r.logs));
										chainlotticket.ticketsOfOwner(web3.eth.accounts[4]).then((r)=>{
											chainlotticket.getTicket(r[0]).then((r)=>{
												console.log(JSON.stringify(r));
											});
										})
									})
									/*cltoken.approve(chainlot.address, 1e11).then(function(r) {
										chainlot.receiveApproval(web3.eth.accounts[4], 1e11, cltoken.address, "0x020101", {from:web3.eth.accounts[4]}).then(function(r) {
											console.log(JSON.stringify(r));
											chainlotticket.ticketsOfOwner(web3.eth.accounts[4]).then((r)=>{
												console.log(JSON.stringify(r));
											})
										});										
									});*/
								});

								/*console.log("buy some tickets");
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
								});*/
							});
						});
					});
				});
			});			
		});
		
	})
})