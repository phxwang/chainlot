pragma solidity 0.4.24;
pragma experimental "v0.5.0";
import "./Interface.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract AffiliateStorage is Ownable{
	using SafeMath for uint;

	mapping(uint=>address) public codeToAddressMap;
	mapping(address=>uint) public addressToCodeMap;
	bytes public constant baseString = "0123456789abcdefghjklmnpqrstuvwxyz";
	uint private constant maxCode = 100000000;

	event NewCode(address user, uint code, bytes32 result);

	function charAt(uint i) public pure returns(uint) {
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
		uint code = addressToCodeMap[user];
		if(code != 0)
			return codeToBytes32(code);
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