pragma solidity ^0.4.18;
import "./Interface.sol";
import "./owned.sol";

contract ChainLotPublic is owned {
	ChainLotInterface public chainlot;
	CLTokenInterface public clToken;
	event BuyTicket(uint poolBlockNumber, bytes numbers, uint ticketCount, uint ticketId, address user, uint blockNumber, uint totalTicketCountSum, uint value);

	function buyTicket(bytes numbers, address referer) payable public {
		chainlot.buyTicket.value(msg.value)(numbers, referer);
	}
	
	function buyRandom(address referer) payable public {
		chainlot.buyRandom.value(msg.value)(referer);
	}

	function setChainLotAddress(address chainlotAddress) onlyOwner external {
		chainlot = ChainLotInterface(chainlotAddress);
	}

	function setCLTokenAddress(address cltokenAddress) onlyOwner external {
		clToken = CLTokenInterface(cltokenAddress);
	}

	function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public {
		if(clToken.transferFrom(_from, this, _value)) {
			clToken.transfer(chainlot, _value);
			chainlot.receiveApproval(_from, _value, _token, _extraData);
		}
	}

	function () payable public {
		buyRandom(0);
	}

}