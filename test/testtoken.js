var ChainLotToken = artifacts.require("./ChainLotToken.sol");

return;
contract("ChainLot", async (accounts) => {
	console.log("from: " + web3.eth.accounts[0]);
	
	let chainlottoken = await ChainLotToken.deployed();
	await chainlottoken.setMinter(web3.eth.accounts[0], true);

	await chainlottoken.sendTransaction({value:2e12});
	await chainlottoken.sendTransaction({from:web3.eth.accounts[3], value:3e12});
	let ctoken = await chainlottoken.circulationToken();
	console.log("circulation token: " + web3.fromWei(ctoken, "ether"));

	for(i=0; i<20; i++) {
		try {
			console.log("-----" + i + "-----")
			let r = await chainlottoken.reedemTokenByEther(web3.eth.accounts[1], {value:1e12});
			//console.log(JSON.stringify(r.logs));
			let reedemPrice = await chainlottoken.currentReedemPrice();
			console.log("reedemPrice of clt: " + web3.fromWei(reedemPrice, "ether"));

			let ctoken = await chainlottoken.circulationToken();
			console.log("circulation token: " + web3.fromWei(ctoken, "ether"));

			let mintersAmount = await chainlottoken.mintersAmount();
			console.log("mintersAmount: " + web3.fromWei(mintersAmount, "ether"));

			//let earlyBirdRawBalance = await chainlottoken.earlyBirdRawBalanceOf(web3.eth.accounts[0]);
			//console.log("earlyBirdRawBalance: " + web3.fromWei(earlyBirdRawBalance, "ether"));
			let frozenAmountOfOwner = await chainlottoken.getFrozenAmountOfOwner();
			console.log("frozenAmountOfOwner: " + web3.fromWei(frozenAmountOfOwner, "ether"));

			
			let sellPrice = await chainlottoken.getPrice();
			console.log("sellPrice of clt: " + web3.fromWei(sellPrice, "ether"));

			let b = await chainlottoken.balanceOf(web3.eth.accounts[0]);
			tosell = (b - frozenAmountOfOwner)/2;
			console.log("to sell: " + web3.fromWei(tosell, "ether") + ", ether " + (web3.fromWei(tosell, "ether") * web3.fromWei(sellPrice, "ether")));

			let tokenEther = await web3.eth.getBalance(chainlottoken.address);
			console.log("tokenEther of clt: " + web3.fromWei(tokenEther, "ether"));

			await chainlottoken.sell(tosell);
			b = await chainlottoken.balanceOf(web3.eth.accounts[0]);
			console.log("token left: " +  web3.fromWei(b, "ether"));
		}
		catch(e) {
			console.log(e);
		}
	}
	
});