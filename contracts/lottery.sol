pragma solidity ^0.4.24;

contract Lottery
{
    address [] public players;
    address public manager;
    uint public amount;
    
    enum State {Started, Finished}
    
    State currentState = State.Started;
    
    constructor()public{
        manager = msg.sender;
    }
    
    function() payable public notManager{
        require(msg.value >= 1 ether,"msg.value >= 1 ether");
        
        currentState = State.Started;
        
        amount += msg.value;
        
        players.push(msg.sender);
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getRewards() public payable onlyManager{
        require(currentState == State.Finished, "lottery is not yet finished");
        
        msg.sender.transfer(getBalance());
    }
    
    function random() public view returns(uint256){
        return uint256 (keccak256(abi.encodePacked(block.number, now, players.length)));
    }
    
    function getWinnerIndex() public view returns(uint256){
        return (random() % players.length);
    }
    
    function getWinner() public playerAvail view returns(address){
   
        return players[getWinnerIndex()];
    }
    
    function getWinnerAmount() public view returns(uint256){
        require(amount != 0, "amount != 0");
        return ((amount * 90)/ 100); // 90 % sends to winner, the rest sends to manager 
    }
    
    function run() external payable onlyManager playerAvail returns(bool)  {
        
        address winner = getWinner();
        
        winner.transfer(getWinnerAmount());
        //reset
        delete players;
        amount = 0;
        currentState = State.Finished;
        return true;
    }
         
    modifier playerAvail(){
       require(0 < players.length, "0 < players.length");
        _;
    }
    
    modifier onlyManager(){
        require(manager == msg.sender, "only manager");
        _;
    }
    
    modifier notManager(){
        require(manager != msg.sender, "not manager");
        _;
    }
}