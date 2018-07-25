pragma solidity 0.4.24;
pragma experimental "v0.5.0";
import "./Interface.sol";
import "./Ownable.sol";

contract ChainLotPublic is Ownable {
	ChainLotInterface public chainlot;
	event BuyTicket(uint poolBlockNumber, bytes numbers, uint ticketCount, uint ticketId, address user, uint blockNumber, uint totalTicketCountSum, uint value);
	event TransferHistoryCut(address user, uint value);
	event NewCode(address user, uint code, bytes32 result);
	event AffiliateTransfer(address affiliate, uint affFee);

	function buyTicket(bytes numbers, bytes affCode) payable public {
		chainlot.buyTicket.value(msg.value)(numbers, affCode);
	}
	
	function buyRandom(uint8 numberCount, bytes affCode) payable public {
		chainlot.buyRandom.value(msg.value)(numberCount, affCode);
	}

	function setChainLotAddress(address chainlotAddress) onlyOwner external {
		chainlot = ChainLotInterface(chainlotAddress);
	}

	function getChainLotCoin() external view returns(address) {
		return chainlot.chainlotCoin();
	}

	function getChainLotTicket() external view returns(address) {
    	return chainlot.chainLotTicket();
  	}

  	function getChainLotToken() external view returns(address) {
    	return chainlot.chainlotToken();
  	}

  	function newAffCode() external {
  		chainlot.newAffCode();
  	}

  	function getAffCode() external view returns(bytes32) {
  		return chainlot.getAffCode();
  	}


	/*function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public {
		if(chainlotCoin.transferFrom(_from, this, _value)) {
			chainlotCoin.transfer(chainlot, _value);
			chainlot.receiveApproval(_from, _value, _token, _extraData);
		}
	}*/

	function () payable external {
		if(msg.value > 0)
			buyRandom(1, "0x0");
	}

	function retrievePoolInfo() external view returns (uint poolTokens, uint poolBlockNumber, uint totalPoolTokens, uint currentPoolIndex) {
		return chainlot.retrievePoolInfo();
	}

	function getWinnerList(uint poolStart, uint poolEnd) external view returns (address[] , uint[] , uint[] ) {
		address[512] memory winnersResult;uint[512] memory valuesResult;uint[512] memory blocksResult;uint count;

		(winnersResult, valuesResult, blocksResult, count) = chainlot.getWinnerList(poolStart, poolEnd);
		if(count > 0) {
			address[] memory winners = new address[](count);
			uint[] memory values = new uint[](count);
			uint[] memory blocks = new uint[](count);
			for(uint i=0;i<count; i++) {
				winners[i] = winnersResult[i];
				values[i] = valuesResult[i];
				blocks[i] = blocksResult[i];
			}
			return(winners, values, blocks);
		}
	}

}