pragma solidity ^0.4.4;
pragma experimental "v0.5.0";

interface ChainLotInterface {
	function mint(address _owner, 
	    bytes _numbers,
	    uint _count) external returns (uint);

	function buyTicket(bytes numbers, address referer) payable external;
	function buyRandom(uint8 numberCount, address referer) payable external;
	function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external;
	function retrievePoolInfo() external view returns (uint poolTokens, uint poolBlockNumber, uint totalPoolTokens, uint poolCount);
	function withDrawHistoryCut(uint poolStart, uint poolEnd, uint[] ticketIds) external;
	function listUserHistoryCut(address user, uint poolStart, uint poolEnd, uint[] ticketIds) external view returns(uint[512] _poolCuts);
	function getWinnerList(uint poolStart, uint _poolEnd) external view returns (address[512] winners, uint[512] values, uint[512] blocks, uint count);
}

interface CLTokenInterface {
	function transfer(address _to, uint _value) external;
	function buy() payable external;
	function balanceOf(address user) external view returns(uint value);
	function transferFrom(address _from, address _to, uint _value) external returns (bool success);
}

interface ChainLotTicketInterface {
	function mint(address _owner, 
    	bytes _numbers,
    	uint _count) external returns (uint);
	function getTicket(uint _ticketId) external view 
    returns (bytes32 numbers, uint count, uint blockNumber);
    function ownerOf(uint _ticketId) external view returns (address owner);
    function totalTicketCountSum() external view returns (uint totalTicketCountSum);
}

interface ChainLotPoolInterface {
	function poolBlockNumber() external view returns(uint blockNumber);
	function tokenSum() external view returns(uint tokenSum);
	function buyTicket(bytes numbers, address referer) payable external;
	function buyRandom(uint8 numberCount, address referer) payable external;
	function withdrawHistoryCut(uint[] ticketIds) external;
	function listUserHistoryCut(address user, uint[] ticketIds) external view returns(uint _historyCut);
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
						CLTokenInterface _clToken,
						ChainLotInterface _chainLot)  external; 

}


