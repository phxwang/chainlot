pragma solidity ^0.4.4;
import "./ChainLotToken.sol";

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
	uint256 public lastAwardedNumber;
	uint256 public lastAwardedTicketIndex;
  uint256 public allTokensCount;
	uint8 public maxWhiteNumberCount;
	uint8 public maxYellowNumberCount;
	mapping(uint => uint) public awardRulesIndex;
  mapping(uint => winnerTicketQueue) public winnerTickets;
	awardRule[] public awardRules;
  ChainLotToken public chainLotToken;
  
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
    uint256[] tokenIds;
    uint256 processedIndex;
  }

	event BuyTicket(uint8[] numbers, uint256 ticketCount, uint256 tokenId, address user, uint256 blockNumber, uint256 allTokensCount);
	event Award(uint8[] jackpotNumbers, uint256 lastestAwardNumber, uint256 lastAwardedNumber, uint256 lastAwardedTicketIndex, uint256 allTokensCount);
	event ToBeAward(uint8[] jackpotNumbers, uint8[] ticketNumber, uint256 ticketCount, uint256 tokenId, address user, uint256 blockNumber, uint256 awardValue);
	event MatchRule(uint8[] jackpotNumbers, uint8[] ticketNumber, uint256 ticketCount, uint256 tokenId, uint256 blockNumber, uint256 ruleId, uint256 ruleEther);
  event Transfer(address winner, uint256 value);
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

		for(uint i=0; i<awardRulesArray.length; i+=3) {
			require(i+3 <= awardRulesArray.length);
			require(awardRulesArray[i]>=0 && awardRulesArray[i]<=maxWhiteNumberCount);
			require(awardRulesArray[i+1]>=0 && awardRulesArray[i+1]<=maxYellowNumberCount);
			awardRules.push(awardRule(awardRulesArray[i],awardRulesArray[i+1],awardRulesArray[i+2]));
			awardRulesIndex[getRuleKey(awardRulesArray[i],awardRulesArray[i+1])] = awardRules.length;
		}

    for(i=0; i<awardRules.length; i++) {
      winnerTickets[i].processedIndex = 0;
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
	function buyTicket(uint8[] numbers) payable public {
    uint256 ticketCount = msg.value/etherPerTicket;
    _buyTicket(numbers, ticketCount);
	}

	//random numbers
	//random seed: number-1 block hash x user address
	function buyRandom() payable public{
    uint256 ticketCount = msg.value/etherPerTicket;
    for(uint256 i=0; i<ticketCount; i++) {
      uint8[] memory numbers = genRandomNumbers(block.number - 1, i+1);
      _buyTicket(numbers, 1);  
    }
	}

  function _buyTicket(uint8[] numbers, uint256 ticketCount) internal {
    require(numbers.length == maxWhiteNumberCount+maxYellowNumberCount);
    for(uint8 i=0; i<maxWhiteNumberCount; i++) {
      require(numbers[i]>=1 && numbers[i]<=maxWhiteNumber); 
    }     
    for(i=maxWhiteNumberCount; i<numbers.length; i++){
      require(numbers[i]>=1&&numbers[i]<=maxYellowNumber);
    }
    
    require(ticketCount > 0);
    uint256 tokenId = chainLotToken.mint(msg.sender, numbersToUint256(numbers), ticketCount);
    allTokensCount = tokenId + 1;
    BuyTicket(numbers, ticketCount, tokenId, msg.sender, block.number, allTokensCount);
  }

	event LOG(uint256 msg);

	//calculate jackpot and other winners and send awards
	function award() onlyOwner public {
		//get last awardIntervalNumber
		uint256 lastestAwardNumber = block.number - 1 - (block.number - 1)%awardIntervalNumber;
		uint8[] memory jackpotNumbers = genRandomNumbers(lastestAwardNumber, 7);
		Award(jackpotNumbers, lastestAwardNumber, lastAwardedTicketIndex, lastAwardedNumber, allTokensCount);

		//calculate winners and send out award
    
		//statistic winners
		for(uint i = lastAwardedTicketIndex; i < allTokensCount; i ++) {
			//only award blockNumber <= lastestAwardNumber
      address mb; uint256 ma; uint256 numbersUint256; uint256 count; uint256 blockNumber;
      (mb, ma, numbersUint256, count, blockNumber) = chainLotToken.getToken(i);
      uint8[] memory numbers = uint256ToNumbers(numbersUint256);
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
        winnerTickets[ruleId].tokenIds.push(i);
        MatchRule(jackpotNumbers, numbers, count, i, blockNumber, ruleId, awardRules[ruleId].awardEther);
			}
			else {
				//MatchRule(jackpotNumbers, allTickets[i].numbers, allTickets[i].count, allTickets[i].user, allTickets[i].blockNumber, ruleId, 0);
			}
			
			lastAwardedTicketIndex = i+1;
			lastAwardedNumber = blockNumber;	
		}

    calculateAwards(jackpotNumbers);

		
    //send awards
		for(i=awardIndex; i<toBeAward.length; i++) {
			//TODO: 10% history user share
			toBeAward[i].user.transfer(toBeAward[i].value);
      Transfer(toBeAward[i].user, toBeAward[i].value);
		}
    awardIndex = toBeAward.length;
	}

  function calculateAwards(uint8[] jackpotNumbers) internal {

    //calculate winners award, from top to bottom, top winners takes all
    uint256 totalBalance = this.balance;
    for(uint i=0; i<awardRules.length; i++){
      if(winnerTickets[i].tokenIds.length > winnerTickets[i].processedIndex && totalBalance > 0) {
        uint256 totalWinnersAward = 0;
        uint256 totalTicketCount = 0;
        for(uint j=winnerTickets[i].processedIndex;j<winnerTickets[i].tokenIds.length; j++) {
          uint256 tokenId = winnerTickets[i].tokenIds[j];
          address mb; uint256 ma; uint256 numbersUint256; uint256 count; uint256 blockNumber;
          (mb, ma, numbersUint256, count, blockNumber) = chainLotToken.getToken(tokenId);
          uint8[] memory numbers = uint256ToNumbers(numbersUint256);
          totalWinnersAward += count * awardRules[i].awardEther;
          totalTicketCount += count;
        }

        CalculateAwards(i, awardRules[i].awardEther, this.balance, totalWinnersAward, totalTicketCount);

        if(totalBalance >= totalWinnersAward) {
          totalBalance -= totalWinnersAward;
        }
        else {
          totalWinnersAward = totalBalance;
          totalBalance = 0;
        }


        for(j=winnerTickets[i].processedIndex;j<winnerTickets[i].tokenIds.length; j++){
          tokenId = winnerTickets[i].tokenIds[j];
          (mb, ma, numbersUint256, count, blockNumber) = chainLotToken.getToken(i);
          numbers = uint256ToNumbers(numbersUint256);
          uint256 awardValue = count * totalWinnersAward / totalTicketCount;
          awardData memory ad = awardData(chainLotToken.ownerOf(tokenId), awardValue);
          toBeAward.push(ad);
          ToBeAward(jackpotNumbers, numbers, count, tokenId, ad.user, blockNumber, awardValue);
        }
      }
      
      //move pointer
      winnerTickets[i].processedIndex = winnerTickets[i].tokenIds.length;

    }
  }

	function genRandomNumbers(uint256 blockNumber, uint256 shift) internal view returns(uint8[] _numbers){
		require(blockNumber < block.number);
		uint256 hash = uint256(block.blockhash(blockNumber));
		uint256 addressInt = uint256(msg.sender);
		uint256 random = hash * addressInt;
    random = random >> shift;
		uint8[] memory numbers = new uint8[](maxWhiteNumberCount+maxYellowNumberCount);
		for(uint8 i=0;i<maxWhiteNumberCount;i++) {
			numbers[i] = uint8(random%maxWhiteNumber + 1);
			random = random >> 8;

		}
		for(i=maxWhiteNumberCount;i<numbers.length;i++) {
			numbers[i] = uint8(random%maxYellowNumber + 1);
			random = random >> 8;

		}
		return numbers;
	}

  function setChainLotTokenAddress(address tokenAddress) onlyOwner external {
    chainLotToken = ChainLotToken(tokenAddress);
  }

  //TODO: list tickets of msg.sender
  function listUserTickets() public {

  }

  function numbersToUint256(uint8[] numbers) internal constant returns(uint256 numbersUint256){
    numbersUint256 = 0;
    for(uint256 i=0;i<numbers.length; i++) {
      numbersUint256 *= 256;
      numbersUint256 += numbers[i];
    }
  }

  function uint256ToNumbers(uint256 numbersUint256) internal constant returns(uint8[] numbers){
    numbers = new uint8[](maxWhiteNumberCount+maxYellowNumberCount);
    for(uint256 i=0; i<numbers.length; i++) {
      numbers[numbers.length - 1 - i] = uint8(numbersUint256 % 256);
      numbersUint256 /= 256;
    }
  }
}
