pragma solidity ^0.4.4;
import "./ChainLotPool.sol";
import "./owned.sol";

interface CLTokenInterface {
	function transfer(address _to, uint256 _value) external;
	function buy() payable external;
	function balanceOf(address user) external view returns(uint value);
}

interface ChainLotTicketInterface {
	function mint(address _owner, 
    	bytes _numbers,
    	uint256 _count) external returns (uint256);
	function getTicket(uint256 _ticketId) external view 
    returns (address mintedBy, uint64 mintedAt, bytes32 numbers, uint256 count, uint256 blockNumber);
    function ownerOf(uint256 _ticketId) external view returns (address owner);
}

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
	
  	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;
  
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
		currentPoolBlockNumber = 0;
	}

	ChainLotPool[] public chainlotPools;
	mapping(address=>bool) public chainlotPoolsMap;
	uint currentPoolBlockNumber;

	//pool range: n*awardIntervalNumber ~ (n+1)awardIntervalNumber-1
	function newPool() public onlyOwner {
		uint nextPoolBlockNumber = block.number - block.number%awardIntervalNumber + awardIntervalNumber;
		ChainLotPool clp;
		if(nextPoolBlockNumber > currentPoolBlockNumber) {
			//generate new pool
			clp = new ChainLotPool(nextPoolBlockNumber, 
				maxWhiteNumber, maxYellowNumber, maxWhiteNumberCount, maxYellowNumberCount, 
				etherPerTicket, awardRulesArray, chainLotTicket, clToken, this);
			chainlotPools.push(clp);
			chainlotPoolsMap[address(clp)] = true;
			GenerateNewPool(currentPoolBlockNumber, nextPoolBlockNumber, chainlotPools.length);
			currentPoolBlockNumber = nextPoolBlockNumber;
		}
	}

	//numbers: uint8[6] 
	//			1-5: <=maxWhiteNumber
	//			6: <=maxYellowNumber
	function buyTicket(bytes numbers, address referer) payable public {
		require(chainlotPools.length > 0);
		chainlotPools[chainlotPools.length-1].buyTicket.value(msg.value)(msg.sender, numbers, referer);
	}

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(address referer) payable public{
		require(chainlotPools.length > 0);
	    chainlotPools[chainlotPools.length-1].buyRandom.value(msg.value)(msg.sender, referer);
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

	//calculate jackpot 
	function prepareAwards() onlyOwner external {
		require(chainlotPools.length > 0);
		chainlotPools[chainlotPools.length-1].prepareAwards();
	}
	//match winners
	function matchAwards(uint8 toMatchCount) onlyOwner external {
		require(chainlotPools.length > 0);
		chainlotPools[chainlotPools.length-1].matchAwards(toMatchCount);
	}

  function calculateAwards() onlyOwner external {
  	require(chainlotPools.length > 0);
	chainlotPools[chainlotPools.length-1].calculateAwards();
  }

  //segment distribute
  function distributeAwards() onlyOwner external {
  	require(chainlotPools.length > 0);
	chainlotPools[chainlotPools.length-1].distributeAwards();
  }

  //TODO: segment send
  function sendAwards() onlyOwner external {
  	require(chainlotPools.length > 0);
	chainlotPools[chainlotPools.length-1].sendAwards();
  }

  function setChainLotTicketAddress(address ticketAddress) onlyOwner external {
    chainLotTicket = ChainLotTicketInterface(ticketAddress);
  }

  function setCLTokenAddress(address tokenAddress) onlyOwner external {
    clToken = CLTokenInterface(tokenAddress);
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

  function withDrawDevCut(uint value) onlyOwner external {
  	clToken.transfer(owner, value);
  }

  //withdraw history cut from pools
  function withDrawHistoryCut(uint start, uint end, uint[] ticketIds) external {
  	require(start >=0);
  	require(end <= chainlotPools.length);
  	for(uint i = start; i < end; i++) {
  		chainlotPools[i].withdrawHistoryCut(msg.sender, ticketIds);
  	}
  }

  function transferUnawarded(uint start, uint end) onlyOwner external {
  	require(start >=0);
  	require(end <= chainlotPools.length-1);
  	for(uint i = start; i < end; i++) {
  		chainlotPools[i].transferUnawarded(address(chainlotPools[chainlotPools.length-1]));
  	}
  }
}
