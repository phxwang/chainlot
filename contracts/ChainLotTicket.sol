pragma solidity ^0.4.18;

import "./ERC721.sol";
import "./owned.sol";
import "./CLToken.sol";

contract ChainLotTicket is ERC721, owned {
  /*** CONSTANTS ***/

  string public constant name = "ChainLotTicket";
  string public constant symbol = "CLT";

  bytes4 constant InterfaceID_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceID_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('ticketsOfOwner(address)'));


  /*** DATA TYPES ***/

  struct Ticket {
    address mintedBy;
    uint64 mintedAt;
    bytes numbers;
    uint256 count;
    uint256 blockNumber;
  }


  /*** STORAGE ***/

  Ticket[] tickets;
  mapping (address => bool) minters;

  mapping (uint256 => address) public ticketIndexToOwner;
  mapping (address => uint256) public ownershipTicketCount;
  mapping (uint256 => address) public ticketIndexToApproved;

  uint public totalTicketCountSum;
  uint public totalWithdrawedToken;
  mapping (address => uint256) public withdrawedToken;
  mapping (address => uint256) public ownershipTicketCountSum;
  CLToken clToken;
  

  /*** EVENTS ***/

  event Mint(address owner, uint256 ticketId);


  /*** INTERNAL FUNCTIONS ***/

  function _owns(address _claimant, uint256 _ticketId) internal view returns (bool) {
    return ticketIndexToOwner[_ticketId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _ticketId) internal view returns (bool) {
    return ticketIndexToApproved[_ticketId] == _claimant;
  }

  function _approve(address _to, uint256 _ticketId) internal {
    ticketIndexToApproved[_ticketId] = _to;

    Approval(ticketIndexToOwner[_ticketId], ticketIndexToApproved[_ticketId], _ticketId);
  }

  function _transfer(address _from, address _to, uint256 _ticketId) internal {
    ownershipTicketCount[_to]++;
    ticketIndexToOwner[_ticketId] = _to;

    if (_from != address(0)) {
      ownershipTicketCount[_from]--;
      delete ticketIndexToApproved[_ticketId];
    }

    Transfer(_from, _to, _ticketId);
  }

  function _mint(address _owner,bytes _numbers,uint256 _count) internal returns (uint256 ticketId) {
    Ticket memory ticket = Ticket({
      mintedBy: _owner,
      mintedAt: uint64(now),
      numbers: _numbers,
      count: _count,
      blockNumber: block.number
    });
    ticketId = tickets.push(ticket) - 1;

    Mint(_owner, ticketId);

    _transfer(0, _owner, ticketId);
    totalTicketCountSum += _count;
    ownershipTicketCountSum[_owner] += _count;
  }


  /*** ERC721 IMPLEMENTATION ***/

  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return ((_interfaceID == InterfaceID_ERC165) || (_interfaceID == InterfaceID_ERC721));
  }

  function totalSupply() public view returns (uint256) {
    return tickets.length;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return ownershipTicketCount[_owner];
  }

  function ownerOf(uint256 _ticketId) external view returns (address owner) {
    owner = ticketIndexToOwner[_ticketId];

    require(owner != address(0));
  }

  function approve(address _to, uint256 _ticketId) external {
    require(_owns(msg.sender, _ticketId));

    _approve(_to, _ticketId);
  }

  function transfer(address _to, uint256 _ticketId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_owns(msg.sender, _ticketId));

    _transfer(msg.sender, _to, _ticketId);
  }

  function transferFrom(address _from, address _to, uint256 _ticketId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_approvedFor(msg.sender, _ticketId));
    require(_owns(_from, _ticketId));

    _transfer(_from, _to, _ticketId);
  }

  function ticketsOfOwner(address _owner) external view returns (uint256[]) {
    uint256 balance = balanceOf(_owner);

    if (balance == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](balance);
      uint256 maxTicketId = totalSupply();
      uint256 idx = 0;

      uint256 ticketId;
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
    uint256 _count) 
    external onlyMinter returns (uint256) {
    return _mint(_owner, _numbers, _count);
  }

  function getTicket(uint256 _ticketId) external view 
    returns (address mintedBy, uint64 mintedAt, bytes32 numbers, uint256 count, uint256 blockNumber) {
    Ticket memory ticket = tickets[_ticketId];

    uint bytesLength = 32;
    if(bytesLength > ticket.numbers.length) bytesLength = ticket.numbers.length;
    for(uint i=0; i<bytesLength; i++) {
      numbers |= bytes32(ticket.numbers[i]&0xFF)>>(i*8);
    }

    mintedBy = ticket.mintedBy;
    mintedAt = ticket.mintedAt;
    //numbers = ticket.numbers;
    count = ticket.count;
    blockNumber = ticket.blockNumber;
  }

  //withdraw token from history cut pool
  //everyone can only withdraw no more than his/her share cut
  //share cut = (totalToken + withdrawedToken) * ticketCountSum / totalTicketCountSum
  function withdrawToken(uint256 value) external {
    uint totalToken = clToken.balanceOf(this);
    uint tokenLeft = (totalToken+totalWithdrawedToken)*ownershipTicketCountSum[msg.sender]/totalTicketCountSum - withdrawedToken[msg.sender];
    require(tokenLeft >= value);
    withdrawedToken[msg.sender] += value;
    totalWithdrawedToken += value;
    clToken.transfer(msg.sender, value);
  }

  function setCLTokenAddress(address tokenAddress) onlyOwner external {
    clToken = CLToken(tokenAddress);
  }
}