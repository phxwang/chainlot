pragma solidity ^0.4.4;
import "./owned.sol";
import "./Interface.sol";

contract ChainLotPool is owned{
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
	uint public historyCut;
	uint public tokenSum;

	enum DrawingStage {INITIED, PREPARED, MATCHED, CALCULATED, SPLITED, DISTRIBUTED, SENT, UNAWARED_TRANSFERED}
	DrawingStage public stage = DrawingStage.INITIED; 


	mapping(uint => uint) public awardRulesIndex;
  	mapping(uint => winnerTicketQueue) public winnerTickets;
  	mapping(uint => winnerTicketQueue) public distributeTickets;
	awardRule[] public awardRules;
  	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;
  	ChainLotInterface public  chainLot;
  	address public drawingToolAddress;
  
  	awardData[] private toBeAward;
  	uint private awardIndex;

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
  	mapping(uint => awardResultByRule) awardResults;

  	

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

  	function ChainLotPool(uint _poolBlockNumber,
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

    	for(i=0; i<awardRules.length; i++) {
      		winnerTickets[i].processedIndex = 0;
      		winnerTickets[i].distributedIndex = 0;
    	}
    	
  	}

  	function setPool(ChainLotTicketInterface _chainLotTicket,
						CLTokenInterface _clToken,
						ChainLotInterface _chainLot, 
						address _drawingToolAddress) public {
  		chainLotTicket = _chainLotTicket;
		clToken = _clToken;
		chainLot = _chainLot;
		owner = tx.origin;
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
		require(stage == DrawingStage.INITIED);
		require(block.number < poolBlockNumber);
		require(address(clToken) != 0);
	    uint ticketCount = msg.value/etherPerTicket;
	    require(ticketCount > 0);
	    clToken.buy.value(msg.value)();
	    tokenSum += msg.value;
	    _buyTicket(tx.origin, numbers, ticketCount, msg.value);
	    if(referer != 0 && tx.origin != referer) {
	    	_buyTicket(referer, numbers, ticketCount, msg.value);	
	    }
	}

	event LOG(uint msg);

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(address referer) payable public{
		bytes memory numbers = genRandomNumbers(block.number - 1, 0);
		buyTicket(numbers, referer);
	}

	function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public {
		require(_token == address(clToken));
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
	}

  	function _buyTicket(address _from, bytes numbers, uint ticketCount, uint _value) internal returns(uint _ticketId){
	    require(numbers.length == maxWhiteNumberCount+maxYellowNumberCount);
	    for(uint8 i=0; i<maxWhiteNumberCount; i++) {
	      require(uint8(numbers[i])>=1 && uint8(numbers[i])<=maxWhiteNumber); 
	    }     
	    for(i=maxWhiteNumberCount; i<numbers.length; i++){
	      require(uint8(numbers[i])>=1&&uint8(numbers[i])<=maxYellowNumber);
	    }
	    
	    require(ticketCount > 0);
	    uint ticketId = chainLot.mint(_from, numbers, ticketCount);
	    allTicketsId.push(ticketId);
	    totalTicketCountSum = chainLotTicket.totalTicketCountSum();
	    BuyTicket(poolBlockNumber, numbers, ticketCount, ticketId, _from, block.number, totalTicketCountSum, _value);
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

	function getWinnerTicket(uint8 ruleId, uint j) onlyDrawingTool external returns(uint id) {
		id = winnerTickets[ruleId].ticketIds[j];
	}

	function getTotalWinnersAward(uint8 ruleId) onlyDrawingTool external view returns(uint award) {
		award = awardResults[ruleId].totalWinnersAward;
	}

	function setTotalWinnersAward(uint8 ruleId, uint award) external onlyDrawingTool {
		awardResults[ruleId].totalWinnersAward = award;
	}


  	function distributeAwards(uint8 ruleId, uint toDistCount) onlyOwner external {
  		require(stage == DrawingStage.SPLITED);
  		//validate last step
	  	//bytes memory jackpotNumbers = jackpotNumbers;
	  	uint endIndex = winnerTickets[ruleId].distributedIndex + toDistCount;
	  	uint ticketIdsLength = winnerTickets[ruleId].ticketIds.length;
	  	if(endIndex > ticketIdsLength) endIndex = ticketIdsLength;
  		if(awardResults[ruleId].totalTicketCount > 0) {
  			for(uint j=winnerTickets[ruleId].distributedIndex;j<endIndex; j++){
	          uint ticketId = winnerTickets[ruleId].ticketIds[j];
	          address mb; uint ma; bytes32 numbers; uint count; uint blockNumber;
	          (mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketId);
	          uint awardValue = count * awardResults[ruleId].totalWinnersAward / awardResults[ruleId].totalTicketCount;
	          awardData memory ad = awardData(chainLotTicket.ownerOf(ticketId), awardValue);
	          toBeAward.push(ad);
	          ToBeAward(jackpotNumbers, numbers, count, ticketId, ad.user, blockNumber, awardValue);
	    	}
  		}
	  	winnerTickets[ruleId].distributedIndex = endIndex;

	  	DistributeAwards(ruleId, toDistCount, endIndex, ticketIdsLength, awardRules.length);

	  	if(ruleId == awardRules.length -1 && endIndex == ticketIdsLength) {
	  		stage = DrawingStage.DISTRIBUTED;
	  	}
  	}

  	function sendAwards(uint toAwardCount) onlyOwner external {
  		require(stage == DrawingStage.DISTRIBUTED);

		uint endIndex = awardIndex + toAwardCount;
		if(endIndex > toBeAward.length) endIndex = toBeAward.length;
		
	  	uint devCut = 0;
	  	uint _historyCut = 0;
	  	uint hCut = 0;
	  	uint userAward = 0;
	  	for(uint i=awardIndex; i<endIndex; i++) {
				userAward = toBeAward[i].value * 88/100;
				//10% history user cut
				hCut = toBeAward[i].value/10;
				_historyCut += hCut;
				//2% dev cut
				devCut += toBeAward[i].value - userAward - hCut;
				clToken.transfer(toBeAward[i].user, userAward);
	      		TransferAward(toBeAward[i].user, userAward);
		}
		if(devCut > 0) {
			clToken.transfer(owner, devCut);
			TransferDevCut(owner, devCut);
		}
		
		//history cut only shared to owner before this pool
		if(_historyCut > 0) {
			historyCut += _historyCut;
			AddHistoryCut(_historyCut, historyCut);
		}
	    awardIndex = endIndex;
	    if(awardIndex == toBeAward.length) {
	    	stage = DrawingStage.SENT;
	    }
	}

	function withdrawHistoryCut(uint[] ticketIds) external {
		uint userCut = calculateUserHistoryCut(ticketIds, tx.origin, false);
	  	clToken.transfer(tx.origin, userCut);
		TransferHistoryCut(tx.origin, userCut);
	}

	function listUserHistoryCut(address user, uint[] ticketIds) external returns(uint _historyCut) {
		return calculateUserHistoryCut(ticketIds, user, true);
	}

	function calculateUserHistoryCut(uint[] ticketIds, address user, bool onlyList) internal returns(uint _cut) {
		if(totalTicketCountSum == 0)
			return 0;
		uint historyTicketCountSum = 0;
	  	address mb; uint ma; bytes32 numbers; uint count; uint blockNumber;
	  	for(uint i=0; i<ticketIds.length; i++) {
	  		(mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketIds[i]);
	  		if(withdrawed[ticketIds[i]] == false 
	  			&& blockNumber < poolBlockNumber 
	  			&& chainLotTicket.ownerOf(ticketIds[i]) == user) {
	  			historyTicketCountSum += count;	
	  			if(!onlyList) {
	  				withdrawed[ticketIds[i]] = true;
	  			}
	  		}		
	  	}
	  	
	  	return historyTicketCountSum * historyCut / totalTicketCountSum;
	}

	function transferUnawarded(address to) onlyOwner external {
		require(stage == DrawingStage.SENT);

      	uint toBeTransfer = clToken.balanceOf(this) - historyCut;
      	if(toBeTransfer > 0) {
      		clToken.transfer(to, toBeTransfer);
      		TransferUnawarded(address(this), to, toBeTransfer);
      	}

      	stage = DrawingStage.UNAWARED_TRANSFERED;
	}

	function genRandomNumbers(uint blockNumber, uint shift) public returns(bytes _numbers){
		require(blockNumber < block.number);
		uint hash = uint(block.blockhash(blockNumber));
		uint addressInt = uint(msg.sender);
		uint256 random = addressInt * hash;
		random = uint256(keccak256(block.timestamp, block.difficulty, hash, addressInt));
		GenRandomNumbers(random, blockNumber, hash, addressInt, shift, block.timestamp, block.difficulty);
		require(random != 0);
		random = random >> shift;
		bytes memory numbers = new bytes(maxWhiteNumberCount+maxYellowNumberCount);
		for(uint8 i=0;i<maxWhiteNumberCount;i++) {
			numbers[i] = byte(random%maxWhiteNumber + 1);
			random = random >> 8;

		}
		for(i=maxWhiteNumberCount;i<numbers.length;i++) {
			numbers[i] = byte(random%maxYellowNumber + 1);
			random = random >> 8;

		}
		return numbers;
	}

	function getAllTicketsCount() external view returns(uint count){
		return allTicketsId.length;
	}

}
