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
	uint256 public etherPerTicket; //10**18/100;
	uint256 public awardIntervalNumber; //50000

	uint256 public allTicketsCount;
	uint8 public maxWhiteNumberCount;
	uint8 public maxYellowNumberCount;
	uint8 public totalNumberCount;

	uint256[] awardRulesArray;
	
	uint256 public lastAwardedNumber;
	uint256 public lastAwardedTicketIndex;
	bytes public latestJackpotNumber;
	uint256 public lastestAwardNumber;

	ChainLotPoolInterface[] public chainlotPools;
	mapping(address=>bool) public chainlotPoolsMap;
	
  	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;
  	ChainLotPoolFactoryInterface public clpFactory;
  
	event BuyTicket(uint poolBlockNumber, bytes numbers, uint256 ticketCount, uint256 ticketId, address user, uint256 blockNumber, uint256 allTicketsCount, uint256 value);
	event PrepareAward(bytes jackpotNumbers, uint256 poolBlockNumber, uint256 allTicketsCount);
	//event PrepareAward(bytes32 jackpotNumbers, uint poolBlockNumber);
	event ToBeAward(bytes jackpotNumbers, bytes32 ticketNumber, uint256 ticketCount, uint256 ticketId, address user, uint256 blockNumber, uint256 awardValue);
	event MatchAwards(bytes jackpotNumbers, uint lastMatchedTicketIndex, uint endIndex, uint allTicketsCount);
	event TransferAward(address winner, uint256 value);
  	event TransferDevCut(address dev, uint256 value);
  	event TransferHistoryCut(address user, uint256 value);
  	event AddHistoryCut(uint added, uint256 total);
  	event CalculateAwards(uint256 ruleId, uint256 awardEther, uint256 totalBalance, uint256 totalWinnersAward, uint256 totalTicketCount);
  	event GenerateNewPool(uint currentPoolBlockNumber, uint nextPoolBlockNumber, uint length);
  	event TransferUnawarded(address to, uint value);
  	event LOG(uint msg);

	function ChainLot(uint8 _maxWhiteNumber, 
						uint8 _maxYellowNumber, 
						uint8 _whiteNumberCount, 
						uint8 _yellowNumberCount, 
						uint256 _etherPerTicket, 
						uint256 _awardIntervalNumber,
						uint256[] _awardRulesArray) public {
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
			awardIntervalNumber, etherPerTicket, awardRulesArray, chainLotTicket, clToken, this);
		if(address(newed) != 0) {
			currentPool = newed;
			chainlotPools.push(currentPool);
			chainlotPoolsMap[address(currentPool)] = true;
		}
	}

	//numbers: uint8[6] 
	//			1-5: <=maxWhiteNumber
	//			6: <=maxYellowNumber
	function buyTicket(bytes numbers, address referer) payable public {
		require(address(currentPool) != 0);
		currentPool.buyTicket.value(msg.value)(msg.sender, numbers, referer);
	}

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(address referer) payable public{
		require(address(currentPool) != 0);
	    currentPool.buyRandom.value(msg.value)(msg.sender, referer);
	}

	modifier onlyPool {
        require(chainlotPoolsMap[msg.sender]);
        _;
  	}

	function mint(address _owner, 
	    bytes _numbers,
	    uint256 _count) 
	    external onlyPool returns (uint256) {
	    return chainLotTicket.mint(_owner, _numbers, _count);
  	}

	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
		/*require(_token == address(clToken));
		require(_extraData.length ==0 || _extraData.length == totalNumberCount);

		uint256 ticketCount = _value/etherPerTicket;
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

	//XXX: need to init award process after new pool;
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

  	function calculateAwards(uint poolIndex) onlyOwner external {
  		ChainLotPoolInterface pool = chainlotPools[poolIndex];
		require(address(pool) != 0);
  		pool.calculateAwards();
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
  }

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
  function withDrawHistoryCut(uint start, uint end, uint[] ticketIds) external {
  	require(start >=0);
  	for(uint i = start; i < end; i++) {
  		chainlotPools[i].withdrawHistoryCut(msg.sender, ticketIds);
  	}
  }

  function transferUnawarded(uint start, uint end) onlyOwner external {
  	require(start >=0);
  	for(uint i = start; i < end; i++) {
  		chainlotPools[i].transferUnawarded(currentPool);
  	}
  }
}
