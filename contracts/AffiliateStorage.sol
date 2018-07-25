pragma solidity 0.4.24;
pragma experimental "v0.5.0";
import "./Interface.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/*
award rules:
  * 5+1 jackpot
  * 5+0 5000 ETH
  * 4+1 50 ETH
  * 4+0 2.5 ETH
  * 3+1 1 ETH
  * 3+0 0.05 ETH
  * 2+1 0.05 ETH
  * 1+1 0.02 ETH
  * 0+1 0.01 ETH
*/
contract AffiliateStorage is Ownable{
	using SafeMath for uint;

	mapping(uint=>address) public codeToAddressMap;
	mapping(address=>uint) public addressToCodeMap;
	bytes public constant baseString = "0123456789abcdefghjklmnpqrstuvwxyz";
	uint private constant maxCode = 100000000;

	event NewCode(address user, uint code, bytes32 result);

	function charAt(uint i) public view returns(uint) {
		return uint(baseString[i]);
	}

	/**
	* code is the last 6 digt of user
	**/
	function newCode(address user) public returns(bytes32 result) {
		require(addressToCodeMap[user] == 0, "user existed");

		uint code = uint(user);
		code = code.sub(code.div(maxCode).mul(maxCode));

		require(code !=0, "code must > 0");

		while(codeToAddressMap[code]!=0) {
			code = code.add(7);
		}
		codeToAddressMap[code] = user;
		addressToCodeMap[user] = code;
		result = codeToBytes32(code);

		emit NewCode(user, code, result);
	}

	function getCode(address user) public view returns(bytes32) {
		return codeToBytes32(addressToCodeMap[user]);
	}

	function getUser(bytes code) public view returns(address) {
		return codeToAddressMap[bytesToCode(code)];
	}

	function codeToBytes32(uint code) public pure returns(bytes32 result) {
		uint bl = baseString.length;
		uint c = code;
		for(uint i=0; i<32; i++) {
			uint b = c.div(bl);
			uint r = c.sub(b.mul(bl));
			result |= bytes32(baseString[r])>>(i*8);
			if(b == 0) break;
			c = b;
		}
		return result;
	}

	function bytesToCode(bytes bs) public pure returns(uint result) {
		uint bl = baseString.length;
		for(uint i=0; i<bs.length; i++) {
			bool foundMatch = false;
			for(uint j=0; j<bl; j++) {
				if(baseString[j] == bs[bs.length - i - 1]) {
					foundMatch = true;
					result = result.mul(bl).add(j);
				}
			}
			if(!foundMatch) return 0;
		}
	}
}