pragma solidity ^0.4.18;
import "./Interface.sol";
import "./owned.sol";

contract ChainLotPublic is owned {
	ChainLotInterface public chainlot;
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

}