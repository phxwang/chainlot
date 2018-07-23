pragma solidity 0.4.24;
pragma experimental "v0.5.0";
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

	uint public coinSum;
	uint8 public maxWhiteNumberCount;
	uint8 public maxYellowNumberCount;
	uint8 public totalNumberCount;
	uint public latestPoolBlockNumber;

	uint[] public awardRulesArray;
	

	ChainLotPoolInterface[] public chainlotPools;
	mapping(address=>bool) public chainlotPoolsMap;
	uint public currentPoolIndex = 0;
	
  	ChainLotTicketInterface public chainLotTicket;
  	ChainLotCoinInterface public chainlotCoin;
  	ChainLotTokenInterface public chainlotToken;
  	ChainLotPoolFactoryInterface public clpFactory;
  	ChainLotPoolInterface public currentPool;
  	
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
  	event GenRandomNumbers(uint random, uint blockNumber, uint hash, uint addressInt, uint shift, uint timestamp, uint difficulty);
  	event MigrateFrom(address chainlotAddress, address poolAddress);
  	event LOG(uint msg);

	constructor(uint8 _maxWhiteNumber, 
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

	function newPool() public onlyOwner {
		ChainLotPoolInterface newed = clpFactory.newPool(latestPoolBlockNumber,maxWhiteNumber, maxYellowNumber, maxWhiteNumberCount, maxYellowNumberCount, 
			awardIntervalNumber, etherPerTicket, awardRulesArray);
		clpFactory.setPool(newed, chainLotTicket, chainlotCoin, ChainLotInterface(this));
		latestPoolBlockNumber = newed.poolBlockNumber();
		if(address(newed) != 0) {
			addPool(newed);
		}
	}

	function addPool(ChainLotPoolInterface newed) internal onlyOwner {
		chainlotPools.push(newed);
		chainlotPoolsMap[address(newed)] = true;

		if(address(currentPool)==0) {
			currentPool = newed;
			currentPoolIndex = chainlotPools.length - 1;
			emit SwitchPool(currentPool.poolBlockNumber(), address(currentPool), currentPoolIndex);
		}
	}

	function checkAndSwitchPool() public {
		require(address(currentPool) != 0);

		//find the right pool
		while(currentPool.poolBlockNumber() <= block.number) {
			require(currentPoolIndex + 1 < chainlotPools.length); // need more pool
			currentPoolIndex ++;
			currentPool = chainlotPools[currentPoolIndex];
			emit SwitchPool(currentPool.poolBlockNumber(), address(currentPool), currentPoolIndex);
		}
	}

	//numbers: uint8[6] 
	//			1-5: <=maxWhiteNumber
	//			6: <=maxYellowNumber
	function buyTicket(bytes numbers, address referer) payable external {
		checkAndSwitchPool();
		currentPool.buyTicket.value(msg.value)(numbers, referer);
		coinSum += msg.value * 9/10;
	}

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(uint8 numberCount, address referer) payable external{
		checkAndSwitchPool();
	    currentPool.buyRandom.value(msg.value)(numberCount, referer);
	    coinSum += msg.value * 9/10;
	}

	modifier onlyPool {
        require(chainlotPoolsMap[msg.sender]);
        _;
  	}

  	function reedemToken(address _owner) external payable onlyPool {
  		chainlotToken.reedemTokenByEther.value(msg.value)(_owner);
  	}

	function mint(address _owner, 
	    bytes _numbers,
	    uint _count) 
	    external onlyPool returns (uint) {
	    return chainLotTicket.mint(_owner, _numbers, _count);
  	}

  	//TODO: security enhancement
	/*function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external {
		checkAndSwitchPool();
		chainlotCoin.transfer(currentPool, _value);
	    currentPool.receiveApproval(_from, _value, _token, _extraData);
	    coinSum += _value;
	}*/

  function setChainLotTicketAddress(address ticketAddress) onlyOwner external {
    chainLotTicket = ChainLotTicketInterface(ticketAddress);
  }

  function setChainLotCoinAddress(address tokenAddress) onlyOwner external {
    chainlotCoin = ChainLotCoinInterface(tokenAddress);
  }

  function setChainLotTokenAddress(address tokenAddress) onlyOwner external {
    chainlotToken = ChainLotTokenInterface(tokenAddress);
  }

  function setChainLotPoolFactoryAddress(address factoryAddress) onlyOwner external {
  	clpFactory = ChainLotPoolFactoryInterface(factoryAddress);
  }

  function withDrawDevCut(uint value) onlyOwner external {
  	chainlotCoin.transfer(owner, value);
  }

  function getPoolCount() external view returns(uint count) {
  	count = chainlotPools.length;
  }

  function retrievePoolInfo() external view returns (uint poolTokens, uint poolBlockNumber, uint totalPoolTokens, uint _currentPoolIndex)  {
  	poolTokens = chainlotCoin.balanceOf(currentPool);
  	poolBlockNumber = currentPool.poolBlockNumber();
  	totalPoolTokens = coinSum;
  	_currentPoolIndex = currentPoolIndex;
  }

  function getWinnerList(uint poolStart, uint _poolEnd) external view returns (address[512] winners, uint[512] values, uint[512] blocks, uint count) {
  	require(_poolEnd > poolStart);
  	uint poolEnd = _poolEnd;
  	if(poolEnd > chainlotPools.length) poolEnd = chainlotPools.length;

  	uint winnersCount = 0;
  	uint poolWinnersCount = 0;
  	address winner; uint value; uint blockNumber;

	for(uint i = 0; i < poolEnd - poolStart; i++) {
		poolWinnersCount= chainlotPools[i].awardIndex();
		blockNumber = chainlotPools[i].poolBlockNumber();
		for(uint j=0; j<poolWinnersCount; j++) {
			if(winnersCount >= 512) break;

			(winner, value) = chainlotPools[i].toBeAward(j);
			winners[winnersCount] = winner;
			values[winnersCount] = value;
			blocks[winnersCount] = blockNumber;
			winnersCount ++;
		}
	}
  	
  	count = winnersCount;
  }

  function migrateFrom(address chainlotAddress) onlyOwner external{
  	ChainLot old = ChainLot(chainlotAddress);
  	for(uint i=0; i<=old.currentPoolIndex(); i++) {
  		address poolAddress = old.chainlotPools(i);
  		if(!chainlotPoolsMap[poolAddress]) {
  			addPool(ChainLotPoolInterface(poolAddress));
  			emit MigrateFrom(chainlotAddress, poolAddress);
  		}
  	}
  	currentPool = old.currentPool();
	currentPoolIndex = old.currentPoolIndex();
  }

}
