pragma solidity ^0.4.16;
pragma experimental "v0.5.0";

import "./owned.sol";
import "./TokenERC20.sol";


contract ChainLotToken is owned, TokenERC20 {

    string public constant name = "CryptoLottoToken";
    string public constant symbol = "CLT";

    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public minters;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event ReedemToken(address target, uint reedemAmount);
    event ReedemTokenByEther(address target, uint etherValue, uint tokenValue);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ChainLotToken(
        uint initialSupply
    ) TokenERC20(initialSupply, name, symbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        super._transfer(_from, _to, _value);
    }

    function reedemToken(address target, uint reedemAmount) onlyOwner external {
        _transfer(this, target, reedemAmount);
        ReedemToken(target, reedemAmount);
    }

    function reedemTokenByEther(address target) payable onlyMinter external {
        //XXX: should use dynamic transfer rate
        uint tokenValue = msg.value;
        if(balanceOf[this] >= tokenValue) {
            _transfer(this, target, tokenValue);
            ReedemTokenByEther(target, msg.value, tokenValue);
        }
    }

    function setMinter(address _minter, bool _enable) external onlyOwner {
        minters[_minter] = _enable;
    }

    modifier onlyMinter {
        require(minters[msg.sender]);
        _;
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner external {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint amount) external {
        require(totalSupply > balanceOf[this]);
        uint etherValue = getPrice() * amount / (10 ** uint(decimals));

        uint previousEther = (address(this)).balance;
        require(previousEther >= etherValue);      // checks if the contract has enough ether to buy

        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(etherValue);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
        assert(previousEther == (etherValue + (address(this)).balance));
    }

    function getPrice() public view returns(uint){
        return (address(this)).balance * (10 ** uint(decimals)) * 5 / (totalSupply - balanceOf[this]);
    }
}
