var ChainLotToken = artifacts.require("./ChainLotToken.sol");

return;
contract("ChainLot", async (accounts) => {
	console.log("from: " + web3.eth.accounts[0]);
	
	let chainlottoken = await ChainLotToken.deployed();
	await chainlottoken.setMinter(web3.eth.accounts[0], true);

	for(i=0; i<10; i++) {
		let r = await chainlottoken.reedemTokenByEther(web3.eth.accounts[1], {value:5e11});
		console.log(JSON.stringify(r.logs));
		let reedemPrice = await chainlottoken.currentReedemPrice();
		console.log("reedemPrice of clt: " + web3.fromWei(reedemPrice, "ether"));
	}
	
});