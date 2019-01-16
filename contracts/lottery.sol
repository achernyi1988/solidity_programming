pragma solidity ^0.4.24;

contract Lottery{
    
    address [] public players;
    address public manager;
    
    constructor()public{
        manager = msg.sender;
    }
    
    function() payable public{
        players.push(msg.sender);
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}