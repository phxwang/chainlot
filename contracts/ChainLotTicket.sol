pragma solidity ^0.4.18;
pragma experimental "v0.5.0";

import "./ERC721.sol";
import "./owned.sol";
import "./CLToken.sol";

contract ChainLotTicket is ERC721, owned {
  /*** CONSTANTS ***/

  string public constant name = "CrytoLottoTicket";
  string public constant symbol = "CLTK";

  bytes4 constant InterfaceID_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceID_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint)')) ^
    bytes4(keccak256('approve(address,uint)')) ^
    bytes4(keccak256('transfer(address,uint)')) ^
    bytes4(keccak256('transferFrom(address,address,uint)')) ^
    bytes4(keccak256('ticketsOfOwner(address)'));


  /*** DATA TYPES ***/

  struct Ticket {
    bytes numbers;
    uint count;
    uint blockNumber;
  }


  /*** STORAGE ***/

  Ticket[] tickets;
  mapping (address => bool) public minters;

  mapping (uint => address) public ticketIndexToOwner;
  mapping (address => uint) public ownershipTicketCount;
  mapping (uint => address) public ticketIndexToApproved;

  uint public totalTicketCountSum;
  

  /*** EVENTS ***/

  event Mint(address owner, uint ticketId);


  /*** INTERNAL FUNCTIONS ***/

  function _owns(address _claimant, uint _ticketId) internal view returns (bool) {
    return ticketIndexToOwner[_ticketId] == _claimant;
  }

  function _approvedFor(address _claimant, uint _ticketId) internal view returns (bool) {
    return ticketIndexToApproved[_ticketId] == _claimant;
  }

  function _approve(address _to, uint _ticketId) internal {
    ticketIndexToApproved[_ticketId] = _to;

    Approval(ticketIndexToOwner[_ticketId], ticketIndexToApproved[_ticketId], _ticketId);
  }

  function _transfer(address _from, address _to, uint _ticketId) internal {
    ownershipTicketCount[_to]++;
    ticketIndexToOwner[_ticketId] = _to;

    if (_from != address(0)) {
      ownershipTicketCount[_from]--;
      delete ticketIndexToApproved[_ticketId];
    }

    Transfer(_from, _to, _ticketId);
  }

  function _mint(address _owner,bytes _numbers,uint _count) internal returns (uint ticketId) {
    Ticket memory ticket = Ticket({
      numbers: _numbers,
      count: _count,
      blockNumber: block.number
    });
    ticketId = tickets.push(ticket) - 1;
    totalTicketCountSum += _count;

    Mint(_owner, ticketId);

    _transfer(0, _owner, ticketId);
  }


  /*** ERC721 IMPLEMENTATION ***/

  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return ((_interfaceID == InterfaceID_ERC165) || (_interfaceID == InterfaceID_ERC721));
  }

  function totalSupply() public view returns (uint) {
    return tickets.length;
  }

  function balanceOf(address _owner) public view returns (uint) {
    return ownershipTicketCount[_owner];
  }

  function ownerOf(uint _ticketId) external view returns (address owner) {
    owner = ticketIndexToOwner[_ticketId];

    require(owner != address(0));
  }

  function approve(address _to, uint _ticketId) external {
    require(_owns(msg.sender, _ticketId));

    _approve(_to, _ticketId);
  }

  function transfer(address _to, uint _ticketId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_owns(msg.sender, _ticketId));

    _transfer(msg.sender, _to, _ticketId);
  }

  function transferFrom(address _from, address _to, uint _ticketId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_approvedFor(msg.sender, _ticketId));
    require(_owns(_from, _ticketId));

    _transfer(_from, _to, _ticketId);
  }

  function ticketsOfOwner(address _owner) public view returns (uint[]) {
    uint balance = balanceOf(_owner);

    if (balance == 0) {
      return new uint[](0);
    } else {
      uint[] memory result = new uint[](balance);
      uint maxTicketId = totalSupply();
      uint idx = 0;

      uint ticketId;
      for (ticketId = 1; ticketId <= maxTicketId; ticketId++) {
        if (ticketIndexToOwner[ticketId] == _owner) {
          result[idx] = ticketId;
          idx++;
        }
      }
    }

    return result;
  }

  /*** OTHER EXTERNAL FUNCTIONS ***/

  function setMinter(address _minter, bool _enable) external onlyOwner {
    minters[_minter] = _enable;
  }

  modifier onlyMinter {
        require(minters[msg.sender]);
        _;
  }

  function mint(address _owner, 
    bytes _numbers,
    uint _count) 
    external onlyMinter returns (uint) {
    return _mint(_owner, _numbers, _count);
  }

  function getTicket(uint _ticketId) external view 
    returns (bytes32 numbers, uint count, uint blockNumber) {
    require(_ticketId < tickets.length);
    Ticket memory ticket = tickets[_ticketId];

    uint bytesLength = 32;
    if(bytesLength > ticket.numbers.length) bytesLength = ticket.numbers.length;
    for(uint i=0; i<bytesLength; i++) {
      numbers |= bytes32(ticket.numbers[i]&0xFF)>>(i*8);
    }

    count = ticket.count;
    blockNumber = ticket.blockNumber;
  }
}