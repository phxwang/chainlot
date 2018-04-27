pragma solidity ^0.4.4;
import "./owned.sol";
import "./Interface.sol";

contract ChainLotPool is owned{
	uint public poolBlockNumber;

	uint8 public maxWhiteNumber; //70;
	uint8 public maxYellowNumber; //25;
	uint256 public etherPerTicket; //10**18/100;

	uint256 public allTicketsCount;
	uint public totalTicketCountSum;
	uint[] public allTicketsId;

	uint8 public maxWhiteNumberCount;
	uint8 public maxYellowNumberCount;
	uint8 public totalNumberCount;
	
	uint256 public lastMatchedTicketIndex;
	bytes public jackpotNumbers;
	bool public preparedAwards;
	uint public historyCut;
	
	mapping(uint => uint) public awardRulesIndex;
  	mapping(uint => winnerTicketQueue) public winnerTickets;
  	mapping(uint => winnerTicketQueue) public distributeTickets;
	awardRule[] public awardRules;
  	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;
  	ChainLotInterface public  chainLot;
  
  	awardData[] private toBeAward;
  	uint256 private awardIndex;

  	mapping(uint => bool) public withdrawed;

	struct awardRule{
		uint256 whiteNumberCount;
		uint256 yellowNumberCount;
		uint256 awardEther;
	}

	struct awardData {
		address user;
		uint256 value;
	}

  	struct winnerTicketQueue {
    	uint256[] ticketIds;
    	uint256 processedIndex;
    	uint256 distributedIndex;
  	}

  	event BuyTicket(uint poolBlockNumber, bytes numbers, uint256 ticketCount, uint256 ticketId, address user, uint256 blockNumber, uint totalTicketCountSum, uint256 value);
	event PrepareAward(bytes jackpotNumbers, uint256 poolBlockNumber, uint256 allTicketsCount);
	event ToBeAward(bytes jackpotNumbers, bytes32 ticketNumber, uint256 ticketCount, uint256 ticketId, address user, uint256 blockNumber, uint256 awardValue);
	event MatchAwards(bytes jackpotNumbers, uint lastMatchedTicketIndex, uint endIndex, uint allTicketsCount);
	event MatchRule(bytes jackpotNumbers, bytes32 ticketNumber, uint256 ticketCount, uint256 ticketId, uint256 blockNumber, uint256 ruleId, uint256 ruleEther);
  	event TransferAward(address winner, uint256 value);
  	event TransferDevCut(address dev, uint256 value);
  	event TransferHistoryCut(address user, uint256 value);
  	event AddHistoryCut(uint added, uint256 total);
  	event CalculateAwards(uint256 ruleId, uint winnersTicketCount, uint256 awardEther, uint256 totalBalance, uint256 totalWinnersAward, uint256 totalTicketCount);
  	event TransferUnawarded(address to, uint value);

  	function ChainLotPool(uint _poolBlockNumber,
  						uint8 _maxWhiteNumber, 
						uint8 _maxYellowNumber, 
						uint8 _whiteNumberCount, 
						uint8 _yellowNumberCount, 
						uint256 _etherPerTicket, 
						uint256[] awardRulesArray,
						ChainLotTicketInterface _chainLotTicket,
						CLTokenInterface _clToken,
						address _chainLot) public {
  		poolBlockNumber = _poolBlockNumber;
  		maxWhiteNumber = _maxWhiteNumber;
		maxYellowNumber = _maxYellowNumber;
		maxWhiteNumberCount = _whiteNumberCount;
		maxYellowNumberCount = _yellowNumberCount;
		etherPerTicket = _etherPerTicket;
		totalNumberCount = maxWhiteNumberCount + maxYellowNumberCount;
		chainLotTicket = _chainLotTicket;
		clToken = _clToken;
		chainLot = ChainLotInterface(_chainLot);

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
    	owner = _chainLot;
  	}

  	function getRuleKey(uint256 _whiteNumberCount, uint256 _yellowNumberCount) internal view returns(uint256 index){
		return _whiteNumberCount*(maxYellowNumberCount+1)+_yellowNumberCount;
	}

	//numbers: uint8[6] 
	//			1-5: <=maxWhiteNumber
	//			6: <=maxYellowNumber
	function buyTicket(address buyer, bytes numbers, address referer) payable public{
		require(block.number < poolBlockNumber);
	    uint256 ticketCount = msg.value/etherPerTicket;
	    clToken.buy.value(msg.value)();
	    _buyTicket(buyer, numbers, ticketCount, msg.value);
	    if(referer != 0 && buyer != referer) {
	    	_buyTicket(referer, numbers, ticketCount, msg.value);	
	    }
	}

	event LOG(uint msg);

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(address buyer, address referer) payable public{
		require(block.number < poolBlockNumber);
		require(address(clToken) != 0);
	    uint256 ticketCount = msg.value/etherPerTicket;
	    bytes memory numbers = genRandomNumbers(block.number - 1, 0);

	    LOG(msg.value);

	    clToken.buy.value(msg.value)();
	    _buyTicket(buyer, numbers, ticketCount, msg.value);  
	    if(referer != 0 && buyer != referer) {
	    	_buyTicket(referer, numbers, ticketCount, msg.value);	
	    }
	}

	/*function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
		require(_token == address(clToken));
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
			_buyTicket(_from, numbers, ticketCount, _value);
	}*/

  	function _buyTicket(address _from, bytes numbers, uint256 ticketCount, uint256 _value) internal returns(uint _ticketId){
	    require(numbers.length == maxWhiteNumberCount+maxYellowNumberCount);
	    for(uint8 i=0; i<maxWhiteNumberCount; i++) {
	      require(uint8(numbers[i])>=1 && uint8(numbers[i])<=maxWhiteNumber); 
	    }     
	    for(i=maxWhiteNumberCount; i<numbers.length; i++){
	      require(uint8(numbers[i])>=1&&uint8(numbers[i])<=maxYellowNumber);
	    }
	    
	    require(ticketCount > 0);
	    uint256 ticketId = chainLot.mint(_from, numbers, ticketCount);
	    allTicketsId.push(ticketId);
	    totalTicketCountSum += chainLotTicket.totalTicketCountSum();
	    BuyTicket(poolBlockNumber, numbers, ticketCount, ticketId, _from, block.number, totalTicketCountSum, _value);
	    return ticketId;
	}

	//calculate jackpot 
	function prepareAwards() onlyOwner external returns(bytes32 numbers){
		require(preparedAwards != true);
		jackpotNumbers = genRandomNumbers(poolBlockNumber, 7);
		PrepareAward(jackpotNumbers, poolBlockNumber, allTicketsId.length);
		preparedAwards = true;
		/*uint bytesLength = 32;
    	if(bytesLength > jackpotNumbers.length) bytesLength = jackpotNumbers.length;
    	for(uint i=0; i<bytesLength; i++) {
      		numbers |= bytes32(jackpotNumbers[i]&0xFF)>>(i*8);
    	}*/
	}

	//match winners
	function matchAwards(uint8 toMatchCount) onlyOwner external {
		require(preparedAwards);
		//require(lastMatchedTicketIndex < allTicketsId.length);
		bytes memory mJackpotNumbers = jackpotNumbers;
		//statistic winners
		uint endIndex = lastMatchedTicketIndex + toMatchCount;
		if(endIndex > allTicketsId.length) endIndex = allTicketsId.length;

		MatchAwards(mJackpotNumbers, lastMatchedTicketIndex, endIndex, allTicketsId.length);

		for(uint i = lastMatchedTicketIndex; i < endIndex; i ++) {
			uint ticketId = allTicketsId[i];
			address mb; uint256 ma; bytes32 numbers; uint256 count; uint256 blockNumber;
	        (mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketId);
	      	
			uint256 matchedWhiteCount = 0;
			uint256 matchedYellowCount = 0;
			for(uint256 j = 0; j < maxWhiteNumberCount; j++) {
				if(numbers[j] == mJackpotNumbers[j]) {
					matchedWhiteCount ++;
				}
			}
			for(j = maxWhiteNumberCount; j < mJackpotNumbers.length; j++) {
				if(numbers[j] == mJackpotNumbers[j]) {
					matchedYellowCount ++;
				}
			}

			uint256 ruleId = awardRulesIndex[getRuleKey(matchedWhiteCount, matchedYellowCount)] - 1;
			
			if(ruleId >= 0 && ruleId < awardRules.length) {
		        //match one rule!
		        winnerTickets[ruleId].ticketIds.push(ticketId);
		        MatchRule(mJackpotNumbers, numbers, count, ticketId, blockNumber, ruleId, awardRules[ruleId].awardEther);
			}
			else {
				//MatchRule(jackpotNumbers, allTickets[i].numbers, allTickets[i].count, allTickets[i].user, allTickets[i].blockNumber, ruleId, 0);
			}
			
			lastMatchedTicketIndex = i+1;
		}
	}

  	struct awardResultByRule {
  		uint totalWinnersAward;
  		uint totalTicketCount;
  		uint balanceLeft;
 	}
  	mapping(uint => awardResultByRule) awardResults;

  	//TODO: segment calculate
  	function calculateAwards() onlyOwner external {
	  	require(lastMatchedTicketIndex == allTicketsId.length);
	  	//calculate winners award, from top to bottom, top winners takes all
	    uint256 totalBalance = clToken.balanceOf(this);
	    for(uint i=0; i<awardRules.length; i++){
	      if(winnerTickets[i].ticketIds.length > winnerTickets[i].processedIndex && totalBalance > 0) {
	        uint256 totalWinnersAward = 0;
	        uint256 totalTicketCount = 0;
	        for(uint j=winnerTickets[i].processedIndex;j<winnerTickets[i].ticketIds.length; j++) {
	          uint256 ticketId = winnerTickets[i].ticketIds[j];
	          address mb; uint256 ma; bytes32 numbers; uint256 count; uint256 blockNumber;
	          (mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketId);
	          totalWinnersAward += count * awardRules[i].awardEther;
	          totalTicketCount += count;
	        }

	        if(totalBalance >= totalWinnersAward) {
	          totalBalance -= totalWinnersAward;
	        }
	        else {
	          totalWinnersAward = totalBalance;
	          totalBalance = 0;
	        }

	        CalculateAwards(i, winnerTickets[i].ticketIds.length, awardRules[i].awardEther, totalBalance, totalWinnersAward, totalTicketCount);

	        awardResults[i]=awardResultByRule(totalWinnersAward, totalTicketCount, totalBalance);
	      }
	      
	      //move pointer
	      winnerTickets[i].processedIndex = winnerTickets[i].ticketIds.length;

	    }
  	}

  	//TODO: segment distribute
  	function distributeAwards() onlyOwner external {
	  	//bytes memory jackpotNumbers = jackpotNumbers;
	  	for(uint i=0; i<awardRules.length; i++){
	  		if(awardResults[i].totalTicketCount > 0) {
	  			for(uint j=winnerTickets[i].distributedIndex;j<winnerTickets[i].ticketIds.length; j++){
		          uint ticketId = winnerTickets[i].ticketIds[j];
		          address mb; uint256 ma; bytes32 numbers; uint256 count; uint256 blockNumber;
		          (mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketId);
		          uint256 awardValue = count * awardResults[i].totalWinnersAward / awardResults[i].totalTicketCount;
		          awardData memory ad = awardData(chainLotTicket.ownerOf(ticketId), awardValue);
		          toBeAward.push(ad);
		          ToBeAward(jackpotNumbers, numbers, count, ticketId, ad.user, blockNumber, awardValue);
		    	}
	  		}
		  	winnerTickets[i].distributedIndex = winnerTickets[i].ticketIds.length;
		}
  	}

  	//TODO: segment send
	function sendAwards() onlyOwner external {
	  	uint devCut = 0;
	  	uint _historyCut = 0;
	  	uint hCut = 0;
	  	uint userAward = 0;
	  	for(uint i=awardIndex; i<toBeAward.length; i++) {
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
	    awardIndex = toBeAward.length;
	}

	function withdrawHistoryCut(address user, uint[] ticketIds) onlyOwner external {
		uint userCut = calculateUserHistoryCut(ticketIds, user);
	  	clToken.transfer(user, userCut);
		TransferHistoryCut(user, userCut);
	}

	function listUserHistoryCut(address user, uint[] ticketIds) external view returns(uint _historyCut) {
		return calculateUserHistoryCut(ticketIds, user);
	}

	function calculateUserHistoryCut(uint[] ticketIds, address user) internal view returns(uint _cut) {
		uint historyTicketCountSum = 0;
	  	address mb; uint256 ma; bytes32 numbers; uint256 count; uint256 blockNumber;
	  	for(uint i=0; i<ticketIds.length; i++) {
	  		(mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketIds[i]);
	  		if(withdrawed[ticketIds[i]] == false 
	  			&& blockNumber < poolBlockNumber 
	  			&& chainLotTicket.ownerOf(ticketIds[i]) == user) {
	  			historyTicketCountSum += count;	
	  			withdrawed[ticketIds[i]] = true;
	  		}		
	  	}
	  	
	  	return historyTicketCountSum * historyCut / totalTicketCountSum;
	}

	function transferUnawarded(address to) onlyOwner external {
      	require(lastMatchedTicketIndex == allTicketsCount);
      	for(uint i=0; i<awardRules.length; i++){
          	require(winnerTickets[i].distributedIndex == winnerTickets[i].ticketIds.length);
      	}
      	require(awardIndex == toBeAward.length);
      	uint toBeTransfer = clToken.balanceOf(this) - historyCut;
      	require(toBeTransfer > 0);
      	clToken.transfer(to, toBeTransfer);
      	TransferUnawarded(to, toBeTransfer);
	}

	function genRandomNumbers(uint256 blockNumber, uint256 shift) internal view returns(bytes _numbers){
		require(blockNumber < block.number);
		uint256 hash = uint256(block.blockhash(blockNumber));
		uint256 addressInt = uint256(msg.sender);
		uint256 random = hash * addressInt;
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

}
