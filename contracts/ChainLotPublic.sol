pragma solidity ^0.4.18;
import "./Interface.sol";
import "./owned.sol";

contract ChainLotPublic is owned {
	ChainLotInterface public chainlot;
	CLTokenInterface public clToken;
	event BuyTicket(uint poolBlockNumber, bytes numbers, uint ticketCount, uint ticketId, address user, uint blockNumber, uint totalTicketCountSum, uint value);
	event TransferHistoryCut(address user, uint value);

	function buyTicket(bytes numbers, address referer) payable public {
		chainlot.buyTicket.value(msg.value)(numbers, referer);
	}
	
	function buyRandom(uint8 numberCount, address referer) payable public {
		chainlot.buyRandom.value(msg.value)(numberCount, referer);
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
		buyRandom(1, 0);
	}

	function retrievePoolInfo() external view returns (uint poolTokens, uint poolBlockNumber, uint totalPoolTokens, uint poolCount) {
		return chainlot.retrievePoolInfo();
	}

	function getWinnerList(uint poolStart, uint poolEnd) external view returns (address[] _winners, uint[] _values, uint[] _blocks) {
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

	//withdraw history cut from pools
  	function withDrawHistoryCut(uint poolStart, uint poolEnd, uint[] ticketIds) external {
  		chainlot.withDrawHistoryCut(poolStart, poolEnd, ticketIds);
  	}


	function listUserHistoryCut(address user, uint poolStart, uint poolEnd, uint[] ticketIds) external view returns(uint[] _poolCuts) {
		//return chainlot.listUserHistoryCut(user, poolStart, poolEnd, ticketIds);
	  	
	  	uint[512] memory pcresult = chainlot.listUserHistoryCut(user, poolStart, poolEnd, ticketIds);
	  	uint[] memory poolCuts = new uint[](poolEnd - poolStart);
	  	for(uint i = 0; i < poolEnd - poolStart; i++) {
	  		poolCuts[i] = pcresult[i];
	  	}
	  	return poolCuts;
	}

}