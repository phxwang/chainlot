pragma solidity ^0.4.4;
import "./owned.sol";
import "./Interface.sol";
import "./ChainLotPool.sol";

contract ChainLotPoolUtils is owned{

	ChainLotTicketInterface public chainLotTicket;
  	CLTokenInterface public clToken;
  	ChainLotInterface public  chainLot;
  
  	event PrepareAward(bytes jackpotNumbers, uint poolBlockNumber, uint allTicketsCount);
	event ToBeAward(bytes jackpotNumbers, bytes32 ticketNumber, uint ticketCount, uint ticketId, address user, uint blockNumber, uint awardValue);
	event MatchAwards(bytes32 jackpotNumbers, uint endIndex, uint allTicketsCount);
	event MatchRule(bytes32 jackpotNumbers, bytes32 ticketNumber, uint ticketCount, uint ticketId, uint blockNumber, uint ruleId);
	event DistributeAwards(uint ruleId, uint toDistCount, uint distributedIndex, uint ticketIdsLength, uint awardRulesLength);
  	event TransferAward(address winner, uint value);
  	event TransferDevCut(address dev, uint value);
  	event TransferHistoryCut(address user, uint value);
  	event AddHistoryCut(uint added, uint total);
  	event CalculateAwards(uint8 ruleId, uint winnersTicketCount, uint awardEther, uint totalWinnersAward, uint totalTicketCount);
  	event SplitAward(uint8 ruleId, uint totalWinnersAward, uint leftBalance);
  	event TransferUnawarded(address from, address to, uint value);
  	event GenRandomNumbers(uint random, uint blockNumber, uint hash, uint addressInt, uint shift, uint timestamp, uint difficulty);

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

  	
  	function setUtils(ChainLotTicketInterface _chainLotTicket,
						CLTokenInterface _clToken,
						ChainLotInterface _chainLot) public {
  		chainLotTicket = _chainLotTicket;
		clToken = _clToken;
		chainLot = _chainLot;
  	}

  	function getRuleKey(uint _whiteNumberCount, uint _yellowNumberCount, uint maxYellowNumberCount) internal view returns(uint index){
		return _whiteNumberCount*(maxYellowNumberCount+1)+_yellowNumberCount;
	}

	//calculate jackpot 
	function prepareAwards(ChainLotPool pool) onlyOwner external {
		require(pool.stage() == ChainLotPool.DrawingStage.INITIED);

		bytes memory jackpotNumbers = genRandomNumbers(pool.poolBlockNumber(), 8, 
			pool.maxWhiteNumberCount(), pool.maxYellowNumberCount(), pool.maxWhiteNumber(), pool.maxYellowNumber());
		pool.setJackpotNumbers(jackpotNumbers);
		PrepareAward(jackpotNumbers, pool.poolBlockNumber(), pool.getAllTicketsCount());
	}

	//match winners
	function matchAwards(ChainLotPool pool, uint toMatchCount) onlyOwner 
		external returns(uint modifiedLastMatchedTicketIndex) {
		require(pool.stage() == ChainLotPool.DrawingStage.PREPARED);

		bytes32 jackpotNumbers = pool.getJackpotNumbers();
		//statistic winners
		uint endIndex = pool.lastMatchedTicketIndex() + toMatchCount;
		uint allTicketsCount = pool.getAllTicketsCount();
		if(endIndex > allTicketsCount) endIndex = allTicketsCount;

		for(uint i = pool.lastMatchedTicketIndex(); i < endIndex; i ++) {
			uint ticketId = pool.allTicketsId(i);
			address mb; uint ma; bytes32 numbers; uint count; uint blockNumber;
	        (mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketId);
	      	
			uint matchedWhiteCount = 0;
			uint matchedYellowCount = 0;
			for(uint j = 0; j < pool.maxWhiteNumberCount(); j++) {
				if(numbers[j] == jackpotNumbers[j]) {
					matchedWhiteCount ++;
				}
			}
			for(j = pool.maxWhiteNumberCount(); j < jackpotNumbers.length; j++) {
				if(numbers[j] == jackpotNumbers[j]) {
					matchedYellowCount ++;
				}
			}

			uint ruleId = pool.awardRulesIndex(getRuleKey(matchedWhiteCount, matchedYellowCount, pool.maxYellowNumberCount())) - 1;
			
			if(ruleId >= 0 && ruleId < pool.getAwardRulesLength()) {
		        //match one rule!
		        pool.pushWinnerTicket(ruleId, ticketId);
		        MatchRule(jackpotNumbers, numbers, count, ticketId, blockNumber, ruleId);
			}
		}

		MatchAwards(jackpotNumbers, endIndex, allTicketsCount);
		return endIndex;
	}


 /* 	function calculateAwards(uint8 ruleId, uint8 toCalcCount) onlyOwner external {
	  	require(stage == DrawingStage.MATCHED);
	  	require(block.number >= poolBlockNumber);
	  	//calculate winners award, from top to bottom, top winners takes all
	    
	      if(winnerTickets[ruleId].ticketIds.length > winnerTickets[ruleId].processedIndex) {
	        uint totalWinnersAward = 0;
	        uint totalTicketCount = 0;
	        uint endIndex = winnerTickets[ruleId].processedIndex + toCalcCount;
	        if(endIndex > winnerTickets[ruleId].ticketIds.length) endIndex = winnerTickets[ruleId].ticketIds.length;
	        for(uint j=winnerTickets[ruleId].processedIndex;j<endIndex; j++) {
	          uint ticketId = winnerTickets[ruleId].ticketIds[j];
	          address mb; uint ma; bytes32 numbers; uint count; uint blockNumber;
	          (mb, ma, numbers, count, blockNumber) = chainLotTicket.getTicket(ticketId);
	          totalWinnersAward += count * awardRules[ruleId].awardEther;
	          totalTicketCount += count;
	        }

	        CalculateAwards(ruleId, endIndex, awardRules[ruleId].awardEther, totalWinnersAward, totalTicketCount);

	        awardResults[ruleId].totalWinnersAward += totalWinnersAward;
	        awardResults[ruleId].totalTicketCount += totalTicketCount;
			//move pointer
	     	winnerTickets[ruleId].processedIndex = endIndex;
	      
	      }

	      if(ruleId == awardRules.length -1 && winnerTickets[ruleId].processedIndex == winnerTickets[ruleId].ticketIds.length) {
	      	stage = DrawingStage.CALCULATED;
	      }

  	}

  	function splitAward() onlyOwner external {
  		require(stage == DrawingStage.CALCULATED);
  		uint totalBalance = clToken.balanceOf(this);
  		for(uint8 i=0; i<awardRules.length; i++) {
  			if(totalBalance >=  awardResults[i].totalWinnersAward) {
	          totalBalance -= awardResults[i].totalWinnersAward;
	        }
	        else {
	          awardResults[i].totalWinnersAward = totalBalance;
	          totalBalance = 0;
	        }
	        SplitAward(i, awardResults[i].totalWinnersAward, totalBalance);
  		}
  		stage = DrawingStage.SPLITED;
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
	}*/

	function genRandomNumbers(uint blockNumber, uint shift, uint8 maxWhiteNumberCount, uint8 maxYellowNumberCount,
	 uint8 maxWhiteNumber, uint8 maxYellowNumber) public returns(bytes _numbers){
		require(blockNumber < block.number);
		uint hash = uint(block.blockhash(blockNumber));
		uint addressInt = uint(tx.origin);
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

}
