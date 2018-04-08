pragma solidity ^0.4.4;
import "./ChainLotTicket.sol";
import "./CLToken.sol";

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
	
	uint256 public lastAwardedNumber;
	uint256 public lastAwardedTicketIndex;
	bytes public latestJackpotNumber;
	uint256 public lastestAwardNumber;
	
	mapping(uint => uint) public awardRulesIndex;
  	mapping(uint => winnerTicketQueue) public winnerTickets;
  	mapping(uint => winnerTicketQueue) public distributeTickets;
	awardRule[] public awardRules;
  	ChainLotTicket public chainLotTicket;
  	CLToken public clToken;
  
  	awardData[] private toBeAward;
  	uint256 private awardIndex;

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

	event BuyTicket(bytes numbers, uint256 ticketCount, uint256 ticketId, address user, uint256 blockNumber, uint256 allTicketsCount, uint256 value);
	event PrepareAward(bytes jackpotNumbers, uint256 lastestAwardNumber, uint256 lastAwardedNumber, uint256 lastAwardedTicketIndex, uint256 allTicketsCount);
	event ToBeAward(bytes jackpotNumbers, bytes32 ticketNumber, uint256 ticketCount, uint256 ticketId, address user, uint256 blockNumber, uint256 awardValue);
	event MatchAwards(bytes jackpotNumbers, uint lastAwardedTicketIndex, uint endIndex, uint allTicketsCount);
	event MatchRule(bytes jackpotNumbers, bytes32 ticketNumber, uint256 ticketCount, uint256 ticketId, uint256 blockNumber, uint256 ruleId, uint256 ruleEther);
  	event TransferAward(address winner, uint256 value);
  	event TransferDevCut(address dev, uint256 value);
  	event TransferHistoryCut(address ticket, uint256 value);
  	event CalculateAwards(uint256 ruleId, uint256 awardEther, uint256 totalBalance, uint256 totalWinnersAward, uint256 totalTicketCount);
	
	function ChainLot(uint8 _maxWhiteNumber, 
						uint8 _maxYellowNumber, 
						uint8 _whiteNumberCount, 
						uint8 _yellowNumberCount, 
						uint256 _etherPerTicket, 
						uint256 _awardIntervalNumber, 
						uint256[] awardRulesArray) public {
		maxWhiteNumber = _maxWhiteNumber;
		maxYellowNumber = _maxYellowNumber;
		maxWhiteNumberCount = _whiteNumberCount;
		maxYellowNumberCount = _yellowNumberCount;
		etherPerTicket = _etherPerTicket;
		awardIntervalNumber = _awardIntervalNumber;
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
		/*
		awardRules.push(awardRule(5,1,-1));
		awardRules.push(awardRule(5,0,5000*10**18));
		awardRules.push(awardRule(4,1,50*10**18));
		awardRules.push(awardRule(4,0,25*10**17));
		awardRules.push(awardRule(3,1,10**18));
		awardRules.push(awardRule(3,0,5**16));
		awardRules.push(awardRule(2,1,5**16));
		awardRules.push(awardRule(1,1,2**16));
		awardRules.push(awardRule(0,1,1**16));
		*/
	}

	function getRuleKey(uint256 _whiteNumberCount, uint256 _yellowNumberCount) internal view returns(uint256 index){
		return _whiteNumberCount*(maxYellowNumberCount+1)+_yellowNumberCount;
	}

	//numbers: uint8[6] 
	//			1-5: <=maxWhiteNumber
	//			6: <=maxYellowNumber
	function buyTicket(bytes numbers, address referer) payable public {
	    uint256 ticketCount = msg.value/etherPerTicket;
	    clToken.buy.value(msg.value)();
	    _buyTicket(msg.sender, numbers, ticketCount, msg.value);
	    if(referer != 0 && msg.sender != referer) {
	    	_buyTicket(referer, numbers, ticketCount, msg.value);	
	    }
	}

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom(address referer) payable public{
	    uint256 ticketCount = msg.value/etherPerTicket;
	    bytes memory numbers = genRandomNumbers(block.number - 1, 0);
	    clToken.buy.value(msg.value)();
	    _buyTicket(msg.sender, numbers, ticketCount, msg.value);  
	    if(referer != 0 && msg.sender != referer) {
	    	_buyTicket(referer, numbers, ticketCount, msg.value);	
	    }
	}

	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
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
	}

  	function _buyTicket(address _from, bytes numbers, uint256 ticketCount, uint256 _value) internal {
	    require(numbers.length == maxWhiteNumberCount+maxYellowNumberCount);
	    for(uint8 i=0; i<maxWhiteNumberCount; i++) {
	      require(uint8(numbers[i])>=1 && uint8(numbers[i])<=maxWhiteNumber); 
	    }     
	    for(i=maxWhiteNumberCount; i<numbers.length; i++){
	      require(uint8(numbers[i])>=1&&uint8(numbers[i])<=maxYellowNumber);
	    }
	    
	    require(ticketCount > 0);
	    uint256 ticketId = chainLotTicket.mint(_from, numbers, ticketCount);
	    allTicketsCount = ticketId + 1;
	    BuyTicket(numbers, ticketCount, ticketId, _from, block.number, allTicketsCount, _value);
	}

	event LOG(uint msg);

	//calculate jackpot 
	function prepareAwards() onlyOwner external {
		//get last awardIntervalNumber
		lastestAwardNumber = block.number - 1 - (block.number - 1)%awardIntervalNumber;
		latestJackpotNumber = genRandomNumbers(lastestAwardNumber, 7);
		PrepareAward(latestJackpotNumber, lastestAwardNumber, lastAwardedTicketIndex, lastAwardedNumber, allTicketsCount);
	}
	//match winners
	function matchAwards(uint8 toMatchCount) onlyOwner external {
		bytes memory jackpotNumbers = latestJackpotNumber;
		//statistic winners
		uint endIndex = lastAwardedTicketIndex + toMatchCount;
		if(endIndex > allTicketsCount) endIndex = allTicketsCount;

		MatchAwards(jackpotNumbers, lastAwardedTicketIndex, endIndex, allTicketsCount);

		for(uint i = lastAwardedTicketIndex; i < endIndex; i ++) {
			//only award blockNumber <= lastestAwardNumber
	        address mb; uint256 ma; bytes32 numbers; uint256 count; uint256 blockNumber;
	        (mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(i);
	      	if(blockNumber > lastestAwardNumber) break;

			uint256 matchedWhiteCount = 0;
			uint256 matchedYellowCount = 0;
			for(uint256 j = 0; j < maxWhiteNumberCount; j++) {
				if(numbers[j] == jackpotNumbers[j]) {
					matchedWhiteCount ++;
				}
			}
			for(j = maxWhiteNumberCount; j < jackpotNumbers.length; j++) {
				if(numbers[j] == jackpotNumbers[j]) {
					matchedYellowCount ++;
				}
			}

			uint256 ruleId = awardRulesIndex[getRuleKey(matchedWhiteCount, matchedYellowCount)] - 1;
			
			if(ruleId >= 0 && ruleId < awardRules.length) {
		        //match one rule!
		        winnerTickets[ruleId].ticketIds.push(i);
		        MatchRule(jackpotNumbers, numbers, count, i, blockNumber, ruleId, awardRules[ruleId].awardEther);
			}
			else {
				//MatchRule(jackpotNumbers, allTickets[i].numbers, allTickets[i].count, allTickets[i].user, allTickets[i].blockNumber, ruleId, 0);
			}
			
			lastAwardedTicketIndex = i+1;
			lastAwardedNumber = blockNumber;	
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

        CalculateAwards(i, awardRules[i].awardEther, this.balance, totalWinnersAward, totalTicketCount);

        awardResults[i]=awardResultByRule(totalWinnersAward, totalTicketCount, totalBalance);
      }
      
      //move pointer
      winnerTickets[i].processedIndex = winnerTickets[i].ticketIds.length;

    }
  }

  //segment distribute
  function distributeAwards() onlyOwner external {
  	bytes memory jackpotNumbers = latestJackpotNumber;
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
  	uint historyCut = 0;
  	uint hCut = 0;
  	uint userAward = 0;
  	for(uint i=awardIndex; i<toBeAward.length; i++) {
			userAward = toBeAward[i].value * 88/100;
			//10% history user cut
			hCut = toBeAward[i].value/10;
			historyCut += hCut;
			//2% dev cut
			devCut += toBeAward[i].value - userAward - hCut;
			clToken.transfer(toBeAward[i].user, userAward);
      		TransferAward(toBeAward[i].user, userAward);
	}
	if(devCut > 0) {
		clToken.transfer(owner, devCut);
		TransferDevCut(owner, devCut);
	}
	
	if(historyCut > 0) {
		clToken.transfer(address(chainLotTicket), historyCut);
		TransferHistoryCut(address(chainLotTicket), historyCut);
	}
    awardIndex = toBeAward.length;
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

  function setChainLotTicketAddress(address ticketAddress) onlyOwner external {
    chainLotTicket = ChainLotTicket(ticketAddress);
  }

  function setCLTokenAddress(address tokenAddress) onlyOwner external {
    clToken = CLToken(tokenAddress);
  }
}
