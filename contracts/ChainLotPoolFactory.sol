pragma solidity ^0.4.4;
pragma experimental "v0.5.0";

import "./ChainLotPool.sol";


contract ChainLotPoolFactory is owned {
  	uint poolCount;

  	event GenerateNewPool(uint latestPoolBlockNumber, uint nextPoolBlockNumber, uint length);
	
	//pool range: n*awardIntervalNumber ~ (n+1)awardIntervalNumber-1
  	function newPool(uint latestPoolBlockNumber,
  						uint8 maxWhiteNumber, 
						uint8 maxYellowNumber, 
						uint8 whiteNumberCount, 
						uint8 yellowNumberCount, 
						uint awardIntervalNumber,
						uint etherPerTicket, 
						uint[] awardRulesArray) onlyOwner  external returns (ChainLotPoolInterface poolAddress){
  	uint startPoolBlockNumber = block.number;
  	if(startPoolBlockNumber < latestPoolBlockNumber) startPoolBlockNumber = latestPoolBlockNumber;
  	uint nextPoolBlockNumber = startPoolBlockNumber - startPoolBlockNumber%awardIntervalNumber + awardIntervalNumber;
	ChainLotPool clp;
	//GenerateNewPool(currentPoolBlockNumber, nextPoolBlockNumber, chainlotPools.length);
		//generate new pool
	clp = new ChainLotPool(nextPoolBlockNumber, 
		maxWhiteNumber, maxYellowNumber, whiteNumberCount, yellowNumberCount, 
		etherPerTicket, awardRulesArray);
	poolCount ++;
	GenerateNewPool(latestPoolBlockNumber, nextPoolBlockNumber, poolCount);
	
  	return ChainLotPoolInterface(clp);
  }

  function setPool(address pool, ChainLotTicketInterface _chainLotTicket,
						CLTokenInterface _clToken,
						ChainLotInterface _chainLot) onlyOwner external {
  	ChainLotPool(pool).setPool(_chainLotTicket, _clToken, _chainLot);

  }
}
