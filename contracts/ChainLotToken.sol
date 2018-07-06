pragma solidity ^0.4.16;
pragma experimental "v0.5.0";

import "./owned.sol";
import "./TokenERC20.sol";


//TODO: price based on the eth balance in contract
contract ChainLotToken is owned, TokenERC20 {

    string public constant name = "CryptoLottoToken";
    string public constant symbol = "CLT";

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

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

    function reedemToken(address target, uint reedemAmount) onlyOwner public {

    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint amount) external {
        require((address(this)).balance >= amount);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
}
