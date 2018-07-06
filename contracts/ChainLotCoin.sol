pragma solidity ^0.4.16;
pragma experimental "v0.5.0";

import "./owned.sol";
import "./TokenERC20.sol";

contract ChainLotCoin is TokenERC20 {

    string public constant name = "CryptoLottoCoin";
    string public constant symbol = "CLC";


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ChainLotCoin(
        uint initialSupply
    ) TokenERC20(initialSupply, name, symbol) public {}

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        _transfer(this, msg.sender, msg.value);              // makes the transfers
    }

    function () payable external {
        buy();
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint amount) external {
        require((address(this)).balance >= amount);      // checks if the contract has enough ether to buy
        msg.sender.transfer(amount);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
        _transfer(msg.sender, this, amount);  // makes the transfers
        
    }
}
