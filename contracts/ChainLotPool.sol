pragma solidity 0.4.24;
pragma experimental "v0.5.0";
import "./Ownable.sol";
import "./Interface.sol";

/*
Pool Smart Contract
used to store all the tickets bought in this pool and all the intermedia status duiring drawing process
*/
contract ChainLotPool is Ownable{
	uint public poolBlockNumber;

	uint8 public maxWhiteNumber; //70;
	uint8 public maxYellowNumber; //25;
	uint public etherPerTicket; //10**18/100;

	uint public allTicketsCount;
	uint public totalTicketCountSum;
	uint[] public allTicketsId;

	uint8 public maxWhiteNumberCount;
	uint8 public maxYellowNumberCount;
	uint8 public totalNumberCount;
	
	uint public lastMatchedTicketIndex;
	bytes public jackpotNumbers;
	uint public devCut;
	uint public futureCut;
	uint public coinSum;
	uint private entropy;

	mapping(uint => uint) public awardRulesIndex;
  	mapping(uint => winnerTicketQueue) public winnerTickets;
  	mapping(uint => winnerTicketQueue) public distributeTickets;
	awardRule[] public awardRules;

  	ChainLotTicketInterface public chainLotTicket;
  	ChainLotCoinInterface public chainlotCoin;
  	ChainLotInterface public  chainLot;
  	address public drawingToolAddress;
  
  	awardData[] public toBeAward;
  	uint public awardIndex;

  	mapping(uint => bool) public withdrawed;

	struct awardRule{
		uint whiteNumberCount;
		uint yellowNumberCount;
		uint awardEther;
	}

	struct awardData {
		address user;
		uint value;
	}

  	struct winnerTicketQueue {
    	uint[] ticketIds;
    	uint processedIndex;
    	uint distributedIndex;
  	}

  	struct awardResultByRule {
  		uint totalWinnersAward;
  		uint totalTicketCount;
 	}
  	mapping(uint => awardResultByRule) public awardResults;

  	enum DrawingStage {INITIED, PREPARED, MATCHED, CALCULATED, SPLITED, DISTRIBUTED, SENT, UNAWARED_TRANSFERED}
	DrawingStage public stage = DrawingStage.INITIED; 

  	

  	event BuyTicket(uint poolBlockNumber, bytes numbers, uint ticketCount, uint ticketId, address user, uint blockNumber, uint totalTicketCountSum, uint value);
	event PrepareAward(bytes jackpotNumbers, uint poolBlockNumber, uint allTicketsCount);
	event ToBeAward(bytes jackpotNumbers, bytes32 ticketNumber, uint ticketCount, uint ticketId, address user, uint blockNumber, uint awardValue);
	event MatchAwards(bytes jackpotNumbers, uint lastMatchedTicketIndex, uint endIndex, uint allTicketsCount);
	event MatchRule(bytes jackpotNumbers, bytes32 ticketNumber, uint ticketCount, uint ticketId, uint blockNumber, uint ruleId, uint ruleEther);
	event DistributeAwards(uint ruleId, uint toDistCount, uint distributedIndex, uint ticketIdsLength, uint awardRulesLength);
  	event TransferAward(address winner, uint value);
  	event TransferDevCut(address dev, uint value);
  	event TransferHistoryCut(address user, uint value);
  	event AddHistoryCut(uint added, uint total);
  	event CalculateAwards(uint8 ruleId, uint winnersTicketCount, uint awardEther, uint totalWinnersAward, uint totalTicketCount);
  	event SplitAward(uint8 ruleId, uint totalWinnersAward, uint leftBalance);
  	event TransferUnawarded(address from, address to, uint value);
  	event GenRandomNumbers(uint random, uint blockNumber, uint hash, uint addressInt, uint shift, uint timestamp, uint difficulty);

  	constructor(uint _poolBlockNumber,
  						uint8 _maxWhiteNumber, 
						uint8 _maxYellowNumber, 
						uint8 _whiteNumberCount, 
						uint8 _yellowNumberCount, 
						uint _etherPerTicket, 
						uint[] awardRulesArray) public {
  		poolBlockNumber = _poolBlockNumber;
  		maxWhiteNumber = _maxWhiteNumber;
		maxYellowNumber = _maxYellowNumber;
		maxWhiteNumberCount = _whiteNumberCount;
		maxYellowNumberCount = _yellowNumberCount;
		etherPerTicket = _etherPerTicket;
		totalNumberCount = maxWhiteNumberCount + maxYellowNumberCount;
		

		for(uint i=0; i<awardRulesArray.length; i+=3) {
			require(i+3 <= awardRulesArray.length);
			require(awardRulesArray[i]>=0 && awardRulesArray[i]<=maxWhiteNumberCount);
			require(awardRulesArray[i+1]>=0 && awardRulesArray[i+1]<=maxYellowNumberCount);
			awardRules.push(awardRule(awardRulesArray[i],awardRulesArray[i+1],awardRulesArray[i+2]));
			awardRulesIndex[getRuleKey(awardRulesArray[i],awardRulesArray[i+1])] = awardRules.length;
		}

    	for(uint i=0; i<awardRules.length; i++) {
      		winnerTickets[i].processedIndex = 0;
      		winnerTickets[i].distributedIndex = 0;
    	}

    	awardIndex = 0;
    	
  	}

  	function setPool(ChainLotTicketInterface _chainLotTicket,
						ChainLotCoinInterface _chainlotCoin,
						ChainLotInterface _chainLot) public {
  		chainLotTicket = _chainLotTicket;
		chainlotCoin = _chainlotCoin;
		chainLot = _chainLot;
		owner = tx.origin;
  	}

  	function setDrawingToolAddress(address _drawingToolAddress) onlyOwner external {
  		drawingToolAddress = _drawingToolAddress;
  	}

  	modifier onlyDrawingTool {
        require(drawingToolAddress == msg.sender);
        _;
  	}

  	function getRuleKey(uint _whiteNumberCount, uint _yellowNumberCount) internal view returns(uint index){
		return _whiteNumberCount*(maxYellowNumberCount+1)+_yellowNumberCount;
	}

	//numbers: uint8[6] 
	//			1-5: <=maxWhiteNumber
	//			6: <=maxYellowNumber
	function buyTicket(bytes numbers, address referer) payable public{
		uint ticketCount = beforeBuy(tx.origin);

	    _buyTicket(tx.origin, numbers, ticketCount, msg.value);
	    if(referer != 0 && tx.origin != referer) {
	    	_buyTicket(referer, numbers, ticketCount, msg.value);	
	    }
	}

	event LOG(uint msg);

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(uint8 numberCount, address referer) payable public{
		require(numberCount > 0);

		uint ticketCount = beforeBuy(tx.origin);

		if(numberCount > ticketCount) numberCount = uint8(ticketCount);
		uint ticketPerNumber = ticketCount / numberCount;

		for(uint8 i=0; i<numberCount; i++) {
			bytes memory numbers = genRandomNumbers(block.number - 1, i*7);

			uint buyCount = ticketPerNumber;
			if(numberCount > 1 && i == numberCount - 1) 
				buyCount = ticketCount - ticketPerNumber * (numberCount - 1);

			_buyTicket(tx.origin, numbers, buyCount, msg.value);
			if(referer != 0 && tx.origin != referer) {
	    		_buyTicket(referer, numbers, buyCount, msg.value);	
	    }
		}
	}

	function beforeBuy(address _from) internal returns(uint ticketCount) {
		require(stage == DrawingStage.INITIED);
		require(block.number < poolBlockNumber);
		require(address(chainlotCoin) != 0);

	   	ticketCount = msg.value/etherPerTicket;
	    require(ticketCount > 0);

	    //10% of pool goes to chainlottoken
	    uint tokenToBuy = msg.value/10;
	    uint coinToBuy = msg.value - tokenToBuy;

	    chainlotCoin.buy.value(coinToBuy)();
	    chainLot.reedemToken.value(tokenToBuy)(_from);
	    coinSum += coinToBuy;
	}

	//TODO: security enhancement
	/*function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public {
		require(_token == address(chainlotCoin));
		require(_extraData.length ==0 || _extraData.length == totalNumberCount);

		uint ticketCount = _value/etherPerTicket;
		require(ticketCount > 0);
		bytes memory numbers;
		if(_extraData.length == 0) {
			numbers = genRandomNumbers(block.number - 1, 0);
		}
		else {
			numbers = _extraData;
		}	

		
		_buyTicket(_from, numbers, ticketCount, _value);
	}*/

  	function _buyTicket(address _from, bytes numbers, uint ticketCount, uint _value) internal returns(uint _ticketId){
	    require(numbers.length == maxWhiteNumberCount+maxYellowNumberCount);
	    for(uint8 i=0; i<maxWhiteNumberCount; i++) {
	      require(uint8(numbers[i])>=1 && uint8(numbers[i])<=maxWhiteNumber); 
	    }     
	    for(uint8 i=maxWhiteNumberCount; i<numbers.length; i++){
	      require(uint8(numbers[i])>=1&&uint8(numbers[i])<=maxYellowNumber);
	    }
	    
	    require(ticketCount > 0);
	    uint ticketId = chainLot.mint(_from, numbers, ticketCount);
	    allTicketsId.push(ticketId);
	    totalTicketCountSum = chainLotTicket.totalTicketCountSum();
	    entropy = uint(keccak256(abi.encodePacked(entropy, totalTicketCountSum, ticketId, numbers, msg.sender)));

	    emit BuyTicket(poolBlockNumber, numbers, ticketCount, ticketId, _from, block.number, totalTicketCountSum, _value);
	    return ticketId;
	}

	//callback from utils
	function setJackpotNumbers(bytes _jackpotNumbers) onlyDrawingTool external {
		jackpotNumbers = _jackpotNumbers;
	}

	function getAwardRulesLength() onlyDrawingTool external view returns(uint length) {
		return awardRules.length;
	}

	function pushWinnerTicket(uint ruleId, uint ticketId) onlyDrawingTool external {
		winnerTickets[ruleId].ticketIds.push(ticketId);
	}

	function getJackpotNumbers() onlyDrawingTool external view returns (bytes32 numbers) {
		bytes memory mJackpotNumbers = jackpotNumbers;
		uint bytesLength = 32;
    	if(bytesLength > mJackpotNumbers.length) bytesLength = mJackpotNumbers.length;
    	for(uint i=0; i<bytesLength; i++) {
      		numbers |= bytes32(mJackpotNumbers[i]&0xFF)>>(i*8);
    	}
	}

	function getWinnerTicketCount(uint8 ruleId) onlyDrawingTool external view returns(uint count) {
		count = winnerTickets[ruleId].ticketIds.length;
	}

	function getProcessedIndex(uint8 ruleId) onlyDrawingTool external view returns(uint index) {
		index = winnerTickets[ruleId].processedIndex;
	}

	function getAwardEther(uint8 ruleId) onlyDrawingTool external view returns(uint _ether) {
		_ether = awardRules[ruleId].awardEther;
	}

	function addTotalWinnersAward(uint8 ruleId, uint totalWinnersAward) onlyDrawingTool external {
		 awardResults[ruleId].totalWinnersAward += totalWinnersAward;
	}

	function addTotalTicketCount(uint8 ruleId, uint totalTicketCount) onlyDrawingTool external {
		 awardResults[ruleId].totalTicketCount += totalTicketCount;
	}

	function setStage(DrawingStage _stage) onlyDrawingTool external {
		stage = _stage;
	}

	function setProcessedIndex(uint8 ruleId, uint index) onlyDrawingTool external {
		winnerTickets[ruleId].processedIndex = index;
	}

	function setLastMatchedTicketIndex(uint index) onlyDrawingTool external {
		lastMatchedTicketIndex = index;
	}

	function getWinnerTicket(uint8 ruleId, uint j) onlyDrawingTool external view returns(uint id) {
		id = winnerTickets[ruleId].ticketIds[j];
	}

	function getTotalWinnersAward(uint8 ruleId) onlyDrawingTool external view returns(uint award) {
		award = awardResults[ruleId].totalWinnersAward;
	}

	function setTotalWinnersAward(uint8 ruleId, uint award) external onlyDrawingTool {
		awardResults[ruleId].totalWinnersAward = award;
	}

	function getDistributedIndex(uint8 ruleId) external onlyDrawingTool view returns(uint index) {
		index = winnerTickets[ruleId].distributedIndex;
	}

	function setDistributedIndex(uint8 ruleId, uint index) onlyDrawingTool external {
		winnerTickets[ruleId].distributedIndex = index;
	}

	function getTotalTicketCount(uint8 ruleId) onlyDrawingTool external view returns(uint count) {
		count = awardResults[ruleId].totalTicketCount;
	}

	function addToBeAward(uint ticketId, uint awardValue) onlyDrawingTool external returns(address userAddress) {
		userAddress = chainLotTicket.ownerOf(ticketId);
		awardData memory ad = awardData(userAddress, awardValue);
	    toBeAward.push(ad);
	}

	function getToBeAwardLength() onlyDrawingTool external view returns(uint length) {
		length = toBeAward.length;
	}

	function transfer(address to, uint value) onlyDrawingTool external {
		if(to != 0 && value != 0)
			chainlotCoin.transfer(to, value);
	}

	function setDevCut(uint cut) onlyDrawingTool external {
		devCut = cut;
	}

	function setFutureCut(uint cut) onlyDrawingTool external {
		futureCut = cut;
	}

	function setAwardIndex(uint index) onlyDrawingTool external {
		awardIndex = index;
	}

	function getEntropy() onlyDrawingTool external view returns (uint _entropy) {
		_entropy = entropy;
	}

	function genRandomNumbers(uint blockNumber, uint shift) public returns(bytes _numbers){
		require(blockNumber < block.number);
		uint hash = uint(blockhash(blockNumber));
		uint addressInt = uint(msg.sender);
		uint256 random = addressInt * hash;
		random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, hash, addressInt, entropy)));
		emit GenRandomNumbers(random, blockNumber, hash, addressInt, shift, block.timestamp, block.difficulty);
		
		require(random != 0);
		random = random >> shift;
		bytes memory numbers = new bytes(maxWhiteNumberCount+maxYellowNumberCount);
		for(uint8 i=0;i<maxWhiteNumberCount;i++) {
			numbers[i] = byte(random%maxWhiteNumber + 1);
			random = random >> 8;

		}
		for(uint8 i=maxWhiteNumberCount;i<numbers.length;i++) {
			numbers[i] = byte(random%maxYellowNumber + 1);
			random = random >> 8;

		}
		return numbers;
	}

	function getAllTicketsCount() external view returns(uint count){
		return allTicketsId.length;
	}

}
