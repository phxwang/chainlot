pragma solidity ^0.4.4;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
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

	struct ticket {
		uint8[] numbers;
		uint256 count;
		address user;
		uint256 blockNumber;
	}

	ticket[] allTickets;

	event BuyTicket(uint8[] numbers, uint256 ticketCount, address user, uint256 blockNumber, uint256 ticketsCount);
	event Award(uint8[] jackpotNumbers, uint256 lastAwardNumber);
	
  	function ChainLot(uint8 _maxWhiteNumber, uint8 _maxYellowNumber, uint256 _etherPerTicket, uint256 _awardIntervalNumber) public {
  		maxWhiteNumber = _maxWhiteNumber;
  		maxYellowNumber = _maxYellowNumber;
  		etherPerTicket = _etherPerTicket;
  		awardIntervalNumber = _awardIntervalNumber;
  	}

  	//uint16[6] 
  	//1-5: <=70
  	//6: <=25
  	function buyTicket(uint8[] numbers) payable public {
  		require(numbers.length == 6);
  		for(uint8 index=0; index<5; index = index+1) {
  			require(numbers[index]>=1 && numbers[index]<=maxWhiteNumber);	
  		} 		
  		require(numbers[5]>=1&&numbers[5]<=maxYellowNumber);

  		uint256 ticketCount = msg.value/etherPerTicket;
  		require(ticketCount > 0);
  		ticket memory t = ticket(numbers, ticketCount, msg.sender, block.number);
  		allTickets.push(t);
  		BuyTicket(t.numbers, t.count, t.user, t.blockNumber, allTickets.length);
  	}

  	//random numbers
  	//random seed: number-1 block hash x user address
  	function buyRandom() payable public returns(uint8[] _numbers){
  		uint8[] memory numbers = genRandomNumbers(block.number - 1);
  		buyTicket(numbers);
  		return numbers;
  	}

  	//calculate jackpot and other winners and send awards
  	function award() onlyOwner public {
  		//get last awardIntervalNumber
  		uint256 lastAwardNumber = block.number - 1 - (block.number - 1)%awardIntervalNumber;
  		uint8[] memory jackpotNumbers = genRandomNumbers(lastAwardNumber);
  		Award(jackpotNumbers, lastAwardNumber);

  		//TODO: calculate winners and send out award

  	}

  	function genRandomNumbers(uint256 blockNumber) internal returns(uint8[] memory _numbers){
  		require(blockNumber < block.number);
  		uint256 hash = uint256(block.blockhash(blockNumber));
  		uint256 addressInt = uint256(msg.sender);
  		uint256 random = hash * addressInt;
  		uint8[] memory numbers = new uint8[](6);
  		for(uint8 index=0;index<5;index=index+1) {
  			numbers[index] = uint8(random%maxWhiteNumber + 1);
  			random = random >> 8;

  		}
  		numbers[5] = uint8(random%maxYellowNumber + 1);
  		return numbers;
  	}
}
