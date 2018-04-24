pragma solidity ^0.4.4;

import "./ChainLotPool.sol";


contract ChainLotPoolFactory is owned {
  	uint currentPoolBlockNumber;
	ChainLotPool[] public chainlotPools;
	mapping(address=>bool) public chainlotPoolsMap;

	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;

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
		chainlotPools.push(clp);
		chainlotPoolsMap[address(clp)] = true;
		GenerateNewPool(currentPoolBlockNumber, nextPoolBlockNumber, chainlotPools.length);
		currentPoolBlockNumber = nextPoolBlockNumber;

		clToken = _clToken;
		chainLotTicket = _chainLotTicket;
	}
  	return ChainLotPoolInterface(clp);
  }

  function latestPool() view external returns(ChainLotPoolInterface pool) {
  	return ChainLotPoolInterface(chainlotPools[chainlotPools.length-1]);
  }

  function validatePool(address pool) view external returns(bool) {
  	return chainlotPoolsMap[pool];
  }

  function poolAt(uint i) view external returns(ChainLotPoolInterface pool) {
  	require(i < chainlotPools.length);
  	return ChainLotPoolInterface(chainlotPools[i]);
  }

  function listAllPool() external view returns (address[] _poolAddresses, uint[] _poolTokens, uint[] _poolTickets) {
  	address[] memory poolAddresses = new address[](chainlotPools.length);
  	uint[] memory poolTokens = new uint[](chainlotPools.length);
  	uint[] memory poolTickets = new uint[](chainlotPools.length);
  	for(uint i=0; i<chainlotPools.length; i++) {
  		poolAddresses[i] = address(chainlotPools[i]);
  		poolTokens[i] = clToken.balanceOf(address(chainlotPools[i]));
  		poolTickets[i] = chainlotPools[i].allTicketsCount();
  	}
  	return (poolAddresses, poolTokens, poolTickets);
  }
}
