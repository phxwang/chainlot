pragma solidity ^0.4.4;

import "./ChainLotPool.sol";


contract ChainLotPoolFactory is owned {
  	uint currentPoolBlockNumber;
  	uint poolCount;

  	event GenerateNewPool(uint currentPoolBlockNumber, uint nextPoolBlockNumber, uint length);
	
	//pool range: n*awardIntervalNumber ~ (n+1)awardIntervalNumber-1
  	function newPool(uint8 maxWhiteNumber, 
						uint8 maxYellowNumber, 
						uint8 whiteNumberCount, 
						uint8 yellowNumberCount, 
						uint awardIntervalNumber,
						uint256 etherPerTicket, 
						uint256[] awardRulesArray,
						ChainLotTicketInterface _chainLotTicket,
						CLTokenInterface _clToken,
						address chainLot) onlyOwner  external returns (ChainLotPoolInterface poolAddress){
  	uint nextPoolBlockNumber = block.number - block.number%awardIntervalNumber + awardIntervalNumber;
	ChainLotPool clp;
	//GenerateNewPool(currentPoolBlockNumber, nextPoolBlockNumber, chainlotPools.length);
	if(nextPoolBlockNumber > currentPoolBlockNumber) {
		//generate new pool
		clp = new ChainLotPool(nextPoolBlockNumber, 
			maxWhiteNumber, maxYellowNumber, whiteNumberCount, yellowNumberCount, 
			etherPerTicket, awardRulesArray, _chainLotTicket, _clToken, chainLot);
		poolCount ++;
		GenerateNewPool(currentPoolBlockNumber, nextPoolBlockNumber, poolCount);
		currentPoolBlockNumber = nextPoolBlockNumber;
	}
  	return ChainLotPoolInterface(clp);
  }
}
