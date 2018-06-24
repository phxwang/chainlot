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

	uint public tokenSum;
	uint8 public maxWhiteNumberCount;
	uint8 public maxYellowNumberCount;
	uint8 public totalNumberCount;
	uint public latestPoolBlockNumber;

	uint[] awardRulesArray;
	

	ChainLotPoolInterface[] public chainlotPools;
	mapping(address=>bool) public chainlotPoolsMap;
	uint public currentPoolIndex = 0;
	
  	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;
  	ChainLotPoolFactoryInterface public clpFactory;
  	ChainLotPoolInterface public currentPool;
  	address drawingToolAddress;
  
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

	function newPool() public onlyOwner {
		ChainLotPoolInterface newed = clpFactory.newPool(latestPoolBlockNumber,maxWhiteNumber, maxYellowNumber, maxWhiteNumberCount, maxYellowNumberCount, 
			awardIntervalNumber, etherPerTicket, awardRulesArray);
		clpFactory.setPool(newed, chainLotTicket, clToken, ChainLotInterface(this), drawingToolAddress);
		latestPoolBlockNumber = newed.poolBlockNumber();
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
		tokenSum += msg.value;
	}

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(address referer) payable public{
		checkAndSwitchPool();
	    currentPool.buyRandom.value(msg.value)(referer);
	    tokenSum += msg.value;
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
		checkAndSwitchPool();
		clToken.transfer(currentPool, _value);
	    currentPool.receiveApproval(_from, _value, _token, _extraData);
	    tokenSum += _value;
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

  function setDrawingToolAddress(address _drawingToolAddress) onlyOwner external{
  	drawingToolAddress = _drawingToolAddress;
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


  function listUserHistoryCut(address user, uint poolStart, uint poolEnd, uint[] ticketIds) external view returns(uint[] _poolCuts) {
  	require(poolEnd > poolStart);
  	require(poolEnd <= chainlotPools.length);

  	uint[] memory poolCuts = new uint[](poolEnd - poolStart);
	for(uint i = poolStart; i < poolEnd; i++) {
  		poolCuts[i-poolStart] = chainlotPools[i].listUserHistoryCut(user, ticketIds);
  	}
  	return poolCuts;
  }

  function retrievePoolInfo() external view returns (uint poolTokens, uint poolBlockNumber, uint totalPoolTokens, uint poolCount)  {
  	poolTokens = clToken.balanceOf(currentPool);
  	poolBlockNumber = currentPool.poolBlockNumber();
  	totalPoolTokens = tokenSum;
  	poolCount = chainlotPools.length;
  }

}
