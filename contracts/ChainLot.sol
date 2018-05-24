pragma solidity ^0.4.4;
import "./Interface.sol";
import "./owned.sol";

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
contract ChainLot is owned{
	uint8 public maxWhiteNumber; //70;
	uint8 public maxYellowNumber; //25;
	uint public etherPerTicket; //10**18/100;
	uint public awardIntervalNumber; //50000

	uint public allTicketsCount;
	uint8 public maxWhiteNumberCount;
	uint8 public maxYellowNumberCount;
	uint8 public totalNumberCount;

	uint[] awardRulesArray;
	
	uint public lastAwardedNumber;
	uint public lastAwardedTicketIndex;
	bytes public latestJackpotNumber;
	uint public lastestAwardNumber;

	ChainLotPoolInterface[] public chainlotPools;
	mapping(address=>bool) public chainlotPoolsMap;
	uint public currentPoolIndex = 0;
	
  	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;
  	ChainLotPoolFactoryInterface public clpFactory;
  
	event BuyTicket(uint poolBlockNumber, bytes numbers, uint ticketCount, uint ticketId, address user, uint blockNumber, uint totalTicketCountSum, uint value);
	event PrepareAward(bytes jackpotNumbers, uint poolBlockNumber, uint allTicketsCount);
	event ToBeAward(bytes jackpotNumbers, bytes32 ticketNumber, uint ticketCount, uint ticketId, address user, uint blockNumber, uint awardValue);
	event MatchAwards(bytes jackpotNumbers, uint lastMatchedTicketIndex, uint endIndex, uint allTicketsCount);
	event MatchRule(bytes jackpotNumbers, bytes32 ticketNumber, uint ticketCount, uint ticketId, uint blockNumber, uint ruleId, uint ruleEther);
  	event TransferAward(address winner, uint value);
  	event TransferDevCut(address dev, uint value);
  	event TransferHistoryCut(address user, uint value);
  	event AddHistoryCut(uint added, uint total);
  	event CalculateAwards(uint8 ruleId, uint winnersTicketCount, uint awardEther, uint totalWinnersAward, uint totalTicketCount);
  	event SplitAward(uint8 ruleId, uint totalWinnersAward, uint leftBalance);
  	event GenerateNewPool(uint currentPoolBlockNumber, uint nextPoolBlockNumber, uint length);
  	event TransferUnawarded(address from, address to, uint value);
  	event SwitchPool(uint currentPoolblockNumber, address currentPool, uint currentPoolIndex);
  	event LOG(uint msg);

	function ChainLot(uint8 _maxWhiteNumber, 
						uint8 _maxYellowNumber, 
						uint8 _whiteNumberCount, 
						uint8 _yellowNumberCount, 
						uint _etherPerTicket, 
						uint _awardIntervalNumber,
						uint[] _awardRulesArray) public {
		maxWhiteNumber = _maxWhiteNumber;
		maxYellowNumber = _maxYellowNumber;
		maxWhiteNumberCount = _whiteNumberCount;
		maxYellowNumberCount = _yellowNumberCount;
		etherPerTicket = _etherPerTicket;
		awardIntervalNumber = _awardIntervalNumber;
		totalNumberCount = maxWhiteNumberCount + maxYellowNumberCount;
		awardRulesArray = _awardRulesArray;
	}

	ChainLotPoolInterface public currentPool;

	function newPool() public onlyOwner {
		ChainLotPoolInterface newed = clpFactory.newPool(maxWhiteNumber, maxYellowNumber, maxWhiteNumberCount, maxYellowNumberCount, 
			awardIntervalNumber, etherPerTicket, awardRulesArray);
		clpFactory.setPool(newed, chainLotTicket, clToken, ChainLotInterface(this));
		if(address(newed) != 0) {
			chainlotPools.push(newed);
			chainlotPoolsMap[address(newed)] = true;

			if(address(currentPool)==0) {
				currentPool = newed;
				currentPoolIndex = chainlotPools.length - 1;
				SwitchPool(currentPool.poolBlockNumber(), address(currentPool), currentPoolIndex);
			}

		}
	}

	function checkAndSwitchPool() internal {
		require(address(currentPool) != 0);

		//find the right pool
		while(currentPool.poolBlockNumber() <= block.number) {
			require(currentPoolIndex + 1 < chainlotPools.length); // need more pool
			currentPoolIndex ++;
			currentPool = chainlotPools[currentPoolIndex];
			SwitchPool(currentPool.poolBlockNumber(), address(currentPool), currentPoolIndex);
		}
	}

	//numbers: uint8[6] 
	//			1-5: <=maxWhiteNumber
	//			6: <=maxYellowNumber
	function buyTicket(bytes numbers, address referer) payable public {
		checkAndSwitchPool();
		currentPool.buyTicket.value(msg.value)(numbers, referer);
	}

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(address referer) payable public{
		checkAndSwitchPool();
	    currentPool.buyRandom.value(msg.value)(referer);
	}

	modifier onlyPool {
        require(chainlotPoolsMap[msg.sender]);
        _;
  	}

	function mint(address _owner, 
	    bytes _numbers,
	    uint _count) 
	    external onlyPool returns (uint) {
	    return chainLotTicket.mint(_owner, _numbers, _count);
  	}

	function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public {
		/*require(_token == address(clToken));
		require(_extraData.length ==0 || _extraData.length == totalNumberCount);

		uint ticketCount = _value/etherPerTicket;
		bytes memory numbers;
		if(_extraData.length == 0) {
			numbers = genRandomNumbers(block.number - 1, 0);
		}
		else {
			numbers = _extraData;
		}	

		if(clToken.transferFrom(_from, this, _value))
			_buyTicket(_from, numbers, ticketCount, _value);*/
	}

	/*//need to init award process after new pool;
	//calculate jackpot 
	function prepareAwards(uint poolIndex) onlyOwner external {
		ChainLotPoolInterface pool = chainlotPools[poolIndex];
		require(address(pool) != 0);
		pool.prepareAwards();
	}
	//match winners
	function matchAwards(uint poolIndex, uint8 toMatchCount) onlyOwner external {
		ChainLotPoolInterface pool = chainlotPools[poolIndex];
		require(address(pool) != 0);
		pool.matchAwards(toMatchCount);
	}

  	function calculateAwards(uint poolIndex, uint8 ruleId, uint8 toCalcCount) onlyOwner external {
  		ChainLotPoolInterface pool = chainlotPools[poolIndex];
		require(address(pool) != 0);
  		pool.calculateAwards(ruleId, toCalcCount);
  	}

  	function splitAward(uint poolIndex) onlyOwner external {
  		ChainLotPoolInterface pool = chainlotPools[poolIndex];
		require(address(pool) != 0);
  		pool.splitAward();
  	}

	//segment distribute
	function distributeAwards(uint poolIndex) onlyOwner external {
		ChainLotPoolInterface pool = chainlotPools[poolIndex];
		require(address(pool) != 0);
		pool.distributeAwards();
  	}

  //TODO: segment send
  function sendAwards(uint poolIndex) onlyOwner external {
  	ChainLotPoolInterface pool = chainlotPools[poolIndex];
	require(address(pool) != 0);
  	pool.sendAwards();
  }*/

  function setChainLotTicketAddress(address ticketAddress) onlyOwner external {
    chainLotTicket = ChainLotTicketInterface(ticketAddress);
  }

  function setCLTokenAddress(address tokenAddress) onlyOwner external {
    clToken = CLTokenInterface(tokenAddress);
  }

  function setChainLotPoolFactoryAddress(address factoryAddress) onlyOwner external {
  	clpFactory = ChainLotPoolFactoryInterface(factoryAddress);
  }

  function withDrawDevCut(uint value) onlyOwner external {
  	clToken.transfer(owner, value);
  }

  //withdraw history cut from pools
  function withDrawHistoryCut(uint poolStart, uint poolEnd, uint[] ticketIds) external {
  	require(poolEnd > poolStart);
  	require(poolEnd <= chainlotPools.length);

  	for(uint i = poolStart; i < poolEnd; i++) {
  		chainlotPools[i].withdrawHistoryCut(ticketIds);
  	}
  }

  //transfer unawarded tokens of awarded pool to newest one
  /*function transferUnawarded(uint poolStart, uint poolEnd) onlyOwner external {
  	checkAndSwitchPool();
  	require(poolEnd > poolStart);
  	require(poolEnd <= currentPoolIndex);
  	for(uint i = poolStart; i < poolEnd; i++) {
  		chainlotPools[i].transferUnawarded(currentPool);
  	}
  }

  function transferUnawardedToAddress(uint poolStart, address poolAddress) onlyOwner external {
  	require(poolEnd > poolStart);
  	require(poolEnd <= currentPoolIndex);
  	for(uint i = poolStart; i < poolEnd; i++) {
  		chainlotPools[i].transferUnawarded(poolAddress);
  	}
  }*/

  function listUserHistoryCut(address user, uint poolStart, uint poolEnd, uint[] ticketIds) external view returns(uint[] _poolCuts) {
  	require(poolEnd > poolStart);
  	require(poolEnd <= chainlotPools.length);

  	uint[] memory poolCuts = new uint[](poolEnd - poolStart);
	for(uint i = poolStart; i < poolEnd; i++) {
  		poolCuts[i-poolStart] = chainlotPools[i].listUserHistoryCut(user, ticketIds);
  	}
  	return poolCuts;
  }

}
