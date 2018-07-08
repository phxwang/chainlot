pragma solidity ^0.4.4;
pragma experimental "v0.5.0";

interface ChainLotInterface {
	function mint(address _owner, 
	    bytes _numbers,
	    uint _count) external returns (uint);
	function reedemToken(address _owner) payable external;
	function buyTicket(bytes numbers, address referer) payable external;
	function buyRandom(uint8 numberCount, address referer) payable external;
	function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external;
	function retrievePoolInfo() external view returns (uint poolTokens, uint poolBlockNumber, uint totalPoolTokens, uint poolCount);
	function getWinnerList(uint poolStart, uint _poolEnd) external view returns (address[512] winners, uint[512] values, uint[512] blocks, uint count);
	function chainlotCoin() external view returns(address);
	function chainlotToken() external view returns(address);
	function chainLotTicket() external view returns(address);
}

interface ChainLotCoinInterface {
	function transfer(address _to, uint _value) external;
	function buy() payable external;
	function balanceOf(address user) external view returns(uint value);
	function transferFrom(address _from, address _to, uint _value) external returns (bool success);
}

interface ChainLotTokenInterface {
	function reedemTokenByEther(address target) payable external;
}

interface ChainLotTicketInterface {
	function mint(address _owner, 
    	bytes _numbers,
    	uint _count) external returns (uint);
	function getTicket(uint _ticketId) external view 
    returns (bytes32 numbers, uint count, uint blockNumber, address owner);
    function ownerOf(uint _ticketId) external view returns (address owner);
    function totalTicketCountSum() external view returns (uint totalTicketCountSum);
}

interface ChainLotPoolInterface {
	function poolBlockNumber() external view returns(uint blockNumber);
	function coinSum() external view returns(uint coinSum);
	function buyTicket(bytes numbers, address referer) payable external;
	function buyRandom(uint8 numberCount, address referer) payable external;
	function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external;
	function awardIndex() external view returns(uint index);
	function toBeAward(uint index) external view returns(address winner, uint value);
}

interface ChainLotPoolFactoryInterface {
	function newPool(uint latestPoolBlockNumber,
						uint8 _maxWhiteNumber, 
						uint8 _maxYellowNumber, 
						uint8 _whiteNumberCount, 
						uint8 _yellowNumberCount, 
						uint _awardIntervalNumber,
						uint _etherPerTicket, 
						uint[] awardRulesArray)  external returns (ChainLotPoolInterface pool);

	function setPool(address pool, ChainLotTicketInterface _chainLotTicket,
						ChainLotCoinInterface _chainlotCoin,
						ChainLotInterface _chainLot)  external; 

}


