var ChainLotToken = artifacts.require("./ChainLotToken.sol");

return;
contract("ChainLot", async (accounts) => {
	console.log("from: " + web3.eth.accounts[0]);
	
	let chainlottoken = await ChainLotToken.deployed();
	await chainlottoken.setMinter(web3.eth.accounts[0], true);

	await chainlottoken.sendTransaction({value:5e12});
	let ctoken = await chainlottoken.circulationToken();
	console.log("circulation token: " + web3.fromWei(ctoken, "ether"));

	for(i=0; i<150; i++) {
		let r = await chainlottoken.reedemTokenByEther(web3.eth.accounts[1], {value:5e11});
		//console.log(JSON.stringify(r.logs));
		let reedemPrice = await chainlottoken.currentReedemPrice();
		console.log("reedemPrice of clt: " + web3.fromWei(reedemPrice, "ether"));
		let ctoken = await chainlottoken.circulationToken();
		console.log("circulation token: " + web3.fromWei(ctoken, "ether"));
	}
	
});