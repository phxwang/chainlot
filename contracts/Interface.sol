pragma solidity ^0.4.4;

interface ChainLotInterface {
	function mint(address _owner, 
	    bytes _numbers,
	    uint _count) external returns (uint);
}

interface CLTokenInterface {
	function transfer(address _to, uint _value) external;
	function buy() payable external;
	function balanceOf(address user) external view returns(uint value);
}

interface ChainLotTicketInterface {
	function mint(address _owner, 
    	bytes _numbers,
    	uint _count) external returns (uint);
	function getTicket(uint _ticketId) external view 
    returns (address mintedBy, uint64 mintedAt, bytes32 numbers, uint count, uint blockNumber);
    function ownerOf(uint _ticketId) external view returns (address owner);
    function totalTicketCountSum() external view returns (uint totalTicketCountSum);
}

interface ChainLotPoolInterface {
	function poolBlockNumber() external view returns(uint blockNumber);
	function buyTicket(address buyer, bytes numbers, address referer) payable public;
	function buyRandom(address buyer, address referer) payable public;
	//calculate jackpot 
	/*function prepareAwards() external returns(bytes32 numbers);
	function matchAwards(uint8 toMatchCount) external;
	function calculateAwards(uint8 ruleId, uint8 toCalcCount) external;
	function splitAward() external;
	function distributeAwards() external;
	function sendAwards() external;*/
	function withdrawHistoryCut(address user, uint[] ticketIds) external;
	//function transferUnawarded(address to) external;
	function listUserHistoryCut(address user, uint[] ticketIds) external view returns(uint _historyCut);
}

interface ChainLotPoolFactoryInterface {
	function newPool(uint8 _maxWhiteNumber, 
						uint8 _maxYellowNumber, 
						uint8 _whiteNumberCount, 
						uint8 _yellowNumberCount, 
						uint _awardIntervalNumber,
						uint _etherPerTicket, 
						uint[] awardRulesArray)  external returns (ChainLotPoolInterface pool);

	function setPool(address pool, ChainLotTicketInterface _chainLotTicket,
						CLTokenInterface _clToken,
						ChainLotInterface _chainLot,
						address _owner)  external; 

}


