pragma solidity 0.4.24;
pragma experimental "v0.5.0";
import "./Ownable.sol";
import "./Interface.sol";
import "./ChainLotPool.sol";

contract DrawingTool is Ownable{

	ChainLotTicketInterface public chainLotTicket;
  	ChainLotCoinInterface public chainlotCoin;
  	
  	event PrepareAward(bytes jackpotNumbers, uint poolBlockNumber, uint allTicketsCount);
	event ToBeAward(bytes32 ticketNumber, uint ticketCount, uint ticketId, address user, uint blockNumber, uint awardValue);
	event MatchAwards(bytes32 jackpotNumbers, uint endIndex, uint allTicketsCount);
	event MatchRule(bytes32 jackpotNumbers, bytes32 ticketNumber, uint ticketCount, uint ticketId, uint blockNumber, uint ruleId);
	event DistributeAwards(uint ruleId, uint toDistCount, uint distributedIndex, uint ticketIdsLength, uint awardRulesLength);
  	event TransferAward(address winner, uint value);
  	event TransferDevCut(address dev, uint value);
  	event CalculateAwards(uint8 ruleId, uint winnersTicketCount, uint awardEther, uint totalWinnersAward, uint totalTicketCount);
  	event SplitAward(uint8 ruleId, uint totalWinnersAward, uint leftBalance);
  	event CutAward(uint devCut, uint futureCut);
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

  	
  	function init(ChainLotTicketInterface _chainLotTicket,
						ChainLotCoinInterface _chainlotCoin) public {
  		chainLotTicket = _chainLotTicket;
		chainlotCoin = _chainlotCoin;
  	}

  	function getRuleKey(uint _whiteNumberCount, uint _yellowNumberCount, uint maxYellowNumberCount) 
  		internal pure returns(uint index){
		return _whiteNumberCount*(maxYellowNumberCount+1)+_yellowNumberCount;
	}

	//calculate jackpot 
	function prepareAwards(address poolAddress) onlyOwner external {
		ChainLotPool pool = ChainLotPool(poolAddress);
		require(pool.stage() == ChainLotPool.DrawingStage.INITIED);

		bytes memory jackpotNumbers = genRandomNumbers(pool.poolBlockNumber(), 8, 
			pool.maxWhiteNumberCount(), pool.maxYellowNumberCount(), pool.maxWhiteNumber(), pool.maxYellowNumber(), pool.getEntropy());
		
		pool.setJackpotNumbers(jackpotNumbers);

		emit PrepareAward(jackpotNumbers, pool.poolBlockNumber(), pool.getAllTicketsCount());

		pool.setStage(ChainLotPool.DrawingStage.PREPARED);
	}

	//match winners
	function matchAwards(address poolAddress, uint toMatchCount) onlyOwner 
		external {
		ChainLotPool pool = ChainLotPool(poolAddress);
		require(pool.stage() == ChainLotPool.DrawingStage.PREPARED);

		bytes32 jackpotNumbers = pool.getJackpotNumbers();
		//statistic winners
		uint endIndex = pool.lastMatchedTicketIndex() + toMatchCount;
		uint allTicketsCount = pool.getAllTicketsCount();
		if(endIndex > allTicketsCount) endIndex = allTicketsCount;

		for(uint i = pool.lastMatchedTicketIndex(); i < endIndex; i ++) {
			uint ticketId = pool.allTicketsId(i);
			
			uint ruleId; bytes32 numbers;uint count;uint blockNumber;
			(ruleId, numbers, count, blockNumber) = matchRule(ticketId, pool, jackpotNumbers);
			
			if(ruleId >= 0 && ruleId < pool.getAwardRulesLength()) {
		        //match one rule!
		        pool.pushWinnerTicket(ruleId, ticketId);
		        emit MatchRule(jackpotNumbers, numbers, count, ticketId, blockNumber, ruleId);
			}
		}

		emit MatchAwards(jackpotNumbers, endIndex, allTicketsCount);

		pool.setLastMatchedTicketIndex(endIndex);

		if(endIndex == allTicketsCount)
			pool.setStage(ChainLotPool.DrawingStage.MATCHED);
		
	}

	event GetRuleKey(bytes32 jackpotNumbers, bytes32 numbers, uint matchedWhiteCount, uint matchedYellowCount, uint ruleKey, uint ruleId);

	function matchRule(uint ticketId, ChainLotPool pool, bytes32 jackpotNumbers) internal view 
		returns(uint ruleId, bytes32 numbers, uint count, uint blockNumber) {
			address _owner;
			(numbers, count, blockNumber, _owner) = chainLotTicket.getTicket(ticketId);
	      	
			uint matchedWhiteCount = 0;
			uint matchedYellowCount = 0;
			for(uint j = 0; j < pool.maxWhiteNumberCount(); j++) {
				if(numbers[j] == jackpotNumbers[j]) {
					matchedWhiteCount ++;
				}
			}
			for(uint j = pool.maxWhiteNumberCount(); j <  pool.maxWhiteNumberCount() + pool.maxYellowNumberCount(); j++) {
				if(numbers[j] == jackpotNumbers[j]) {
					matchedYellowCount ++;
				}
			}

			uint ruleKey = getRuleKey(matchedWhiteCount, matchedYellowCount, pool.maxYellowNumberCount());
			ruleId = pool.awardRulesIndex(ruleKey) - 1;

			//GetRuleKey(jackpotNumbers, numbers, matchedWhiteCount, matchedYellowCount, ruleKey, ruleId);
	}


  	function calculateAwards(address poolAddress, uint8 ruleId, uint8 toCalcCount) onlyOwner external {
  		ChainLotPool pool = ChainLotPool(poolAddress);
	  	require(pool.stage() == ChainLotPool.DrawingStage.MATCHED);
	  	//calculate winners award, from top to bottom, top winners takes all

	  	uint winnerTicketCount = pool.getWinnerTicketCount(ruleId);
	  	uint processedIndex = pool.getProcessedIndex(ruleId);
	  	uint awardEther = pool.getAwardEther(ruleId);
	    uint endIndex = processedIndex + toCalcCount;
	        
	    if(winnerTicketCount > processedIndex) {
	        if(endIndex > winnerTicketCount) endIndex = winnerTicketCount;

	        doCaculate(pool, ruleId, processedIndex, endIndex, awardEther);    
	    }

	    if(ruleId == pool.getAwardRulesLength() -1 && endIndex == winnerTicketCount) {
	      	pool.setStage(ChainLotPool.DrawingStage.CALCULATED);
	    }

  	}

  	function doCaculate(ChainLotPool pool, uint8 ruleId, uint processedIndex, uint endIndex, uint awardEther) 
  		onlyOwner internal {
	    bytes32 numbers; uint count; uint blockNumber; address _owner;
	    uint totalWinnersAward = 0;
	    uint totalTicketCount = 0;
	            
	    for(uint j=processedIndex;j<endIndex; j++) {
          uint ticketId = pool.getWinnerTicket(ruleId, j);
          (numbers, count, blockNumber, _owner) = chainLotTicket.getTicket(ticketId);
          totalWinnersAward += count * awardEther;
          totalTicketCount += count;
        }

        pool.addTotalWinnersAward(ruleId, totalWinnersAward);
        pool.addTotalTicketCount(ruleId, totalTicketCount);
		//move pointer
     	pool.setProcessedIndex(ruleId, endIndex);

     	emit CalculateAwards(ruleId, endIndex, awardEther, totalWinnersAward, totalTicketCount); 
  	}
  	
  	function splitAward(address poolAddress) onlyOwner external {
  		ChainLotPool pool = ChainLotPool(poolAddress);
  		require(pool.stage() == ChainLotPool.DrawingStage.CALCULATED);

  		uint totalBalance = chainlotCoin.balanceOf(poolAddress);
  		uint futureCut = totalBalance/10;
  		uint devCut = totalBalance/50;

  		totalBalance = totalBalance - futureCut - devCut;

  		for(uint8 i=0; i<pool.getAwardRulesLength(); i++) {
  			if(totalBalance >=  pool.getTotalWinnersAward(i)) {
	          totalBalance -= pool.getTotalWinnersAward(i);
	        }
	        else {
	          pool.setTotalWinnersAward(i, totalBalance);
	          totalBalance = 0;
	        }
	        emit SplitAward(i, pool.getTotalWinnersAward(i), totalBalance);
  		}

  		pool.setDevCut(devCut);
  		pool.setFutureCut(futureCut);

  		emit CutAward(devCut, futureCut);

  		pool.setStage(ChainLotPool.DrawingStage.SPLITED);
  	}

  

  	function distributeAwards(address poolAddress, uint8 ruleId, uint toDistCount) onlyOwner external {
  		ChainLotPool pool = ChainLotPool(poolAddress);
  		require(pool.stage() == ChainLotPool.DrawingStage.SPLITED);
		
		uint winnerTicketCount = pool.getWinnerTicketCount(ruleId);
	  	uint distributedIndex = pool.getDistributedIndex(ruleId);
	  	uint endIndex = distributedIndex + toDistCount;			  	

	  	if(winnerTicketCount > distributedIndex) {
	  		if(endIndex > winnerTicketCount) endIndex = winnerTicketCount;

		  	doDistribute(pool, ruleId, distributedIndex, endIndex);

		  	emit DistributeAwards(ruleId, toDistCount, endIndex, winnerTicketCount, pool.getAwardRulesLength());
	  	}

	  	if(ruleId == pool.getAwardRulesLength() -1 && endIndex == winnerTicketCount) {
		  		pool.setStage(ChainLotPool.DrawingStage.DISTRIBUTED);
		}
  	}

  	function doDistribute(ChainLotPool pool, uint8 ruleId, uint distributedIndex, uint endIndex) onlyOwner internal{
  		uint totalTicketCount = pool.getTotalTicketCount(ruleId);
	  	uint totalWinnerAward = pool.getTotalWinnersAward(ruleId);

	  	if(totalTicketCount > 0) {
	  		bytes32 numbers; uint count; uint blockNumber; address _owner;
	          
  			for(uint j=distributedIndex; j<endIndex; j++){
	          uint ticketId = pool.getWinnerTicket(ruleId, j);
	          (numbers, count, blockNumber, _owner) = chainLotTicket.getTicket(ticketId);
	          uint awardValue = count * totalWinnerAward / totalTicketCount;
	          address awardUser = pool.addToBeAward(ticketId, awardValue);
	          emit ToBeAward(numbers, count, ticketId, awardUser, blockNumber, awardValue);
	    	}
  		}
	  	pool.setDistributedIndex(ruleId, endIndex);
  	}

  	function sendAwards(address poolAddress, uint toAwardCount) onlyOwner external {
  		ChainLotPool pool = ChainLotPool(poolAddress);
  		require(pool.stage() == ChainLotPool.DrawingStage.DISTRIBUTED);
  		
  		uint startIndex = pool.awardIndex();
  		uint endIndex = startIndex + toAwardCount;
		uint toBeAwardLength = pool.getToBeAwardLength();
		if(endIndex > toBeAwardLength) endIndex = toBeAwardLength;

		pool.setAwardIndex(endIndex);
	    if(endIndex == toBeAwardLength) {
	    	pool.setStage(ChainLotPool.DrawingStage.SENT);
	    }
		
	  	address user; uint value; 
	  	for(uint i=startIndex; i<endIndex; i++) {
	  		(user, value) = pool.toBeAward(i);
			pool.transfer(user, value);
      		emit TransferAward(user, value);
		}

		uint devCut = pool.devCut();

		if(devCut > 0) {
			pool.setDevCut(0);
			pool.transfer(owner, devCut);
			emit TransferDevCut(owner, devCut);
		}
	}

	function transferUnawarded(address poolAddress, address to) onlyOwner external {
		ChainLotPool pool = ChainLotPool(poolAddress);
  		require(pool.stage() == ChainLotPool.DrawingStage.SENT);

      	uint toBeTransfer = chainlotCoin.balanceOf(poolAddress);
      	if(toBeTransfer > 0) {
      		pool.transfer(to, toBeTransfer);
      		emit TransferUnawarded(poolAddress, to, toBeTransfer);
      	}

      	pool.setStage(ChainLotPool.DrawingStage.UNAWARED_TRANSFERED);
	}

	function genRandomNumbers(uint blockNumber, uint shift, uint8 maxWhiteNumberCount, uint8 maxYellowNumberCount,
	 uint8 maxWhiteNumber, uint8 maxYellowNumber, uint entropy) public view returns(bytes _numbers){
		require(blockNumber < block.number);
		uint hash = uint(blockhash(blockNumber));
		uint addressInt = uint(msg.sender);
		uint random = 0;
		for(uint8 i=0; i<6; i++) {
			random = uint(keccak256(abi.encodePacked(entropy, hash, addressInt)));
			uint nextBlockNumber = random - (random/blockNumber)*blockNumber;
			hash = uint(blockhash(nextBlockNumber));
		}

		//GenRandomNumbers(random, blockNumber, hash, addressInt, shift, block.timestamp, block.difficulty);

		return uintToNumbers(random, shift, maxWhiteNumberCount, maxYellowNumberCount, maxWhiteNumber, maxYellowNumber);
	}

	function uintToNumbers(uint _random, uint shift, uint8 maxWhiteNumberCount, uint8 maxYellowNumberCount,
		uint8 maxWhiteNumber, uint8 maxYellowNumber) private pure returns(bytes) {
		require(_random != 0);
		uint random = _random;
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

}
