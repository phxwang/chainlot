var AffiliateStorage = artifacts.require("./AffiliateStorage.sol");

return;

contract("ChainLot", async (accounts) => {
	let affstore = await AffiliateStorage.deployed();

	for(var i=0; i<10; i++) {
		result = await affstore.newCode(web3.eth.accounts[i]);
		console.log(JSON.stringify(result.logs[0].args.result));
		s = await bytes32ToStr(result.logs[0].args.result);
		console.log("new code: " + s);

		b = await strToBytes32(s);
		console.log(b);
		result = await affstore.getUser(b);
		console.log("get user: " + result);

		result = await affstore.getCode(web3.eth.accounts[i]);
		s = await bytes32ToStr(result);
		console.log("get code: " + s);
	}

	result = await affstore.getUser("0x1111");
	console.log("get user: " + result);
	

	/*let result = await affstore.codeToBytes32(142143414);
	console.log("result: " + result);
	console.log(result.substring(0,6));
	let s = await bytes32ToStr(result);
	console.log("str: " + s);

	result = await affstore.bytesToCode(result.substring(0,14));
	console.log(JSON.stringify(result));*/

	//let r = await affstore.charAt(22);
	//console.log(JSON.stringify(r));
});

var bytes32ToStr = async function(str) {
    result = "";
    for(i=2; i<str.length; i+=2) {
      r = parseInt(str.substring(i, i+2), 16);
      //console.log(r);
      if(r == 0) break;
      result += String.fromCharCode(r);
    }
    return result;
}

var strToBytes32 = async function(str) {
	result = "0x";
	for(i=0; i<str.length; i++) {
		//console.log(str.charAt(i) + ", " +str.charCodeAt(i).toString(16));
		var b = str.charCodeAt(i).toString(16);
		if(b.length == 0) b = "0" + b;
		result += b;
	}
	return result;
}