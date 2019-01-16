pragma solidity ^0.4.24;



contract AuctionCreator{
    address [] public  auctions;    
    
    function createAuction() public {
        auctions.push(new Auction(msg.sender));
    }
    
    function getAuctions() public view returns (address []){
        return auctions;
    }
}

contract Auction{
    
    address public owner;
    uint256 public startBlock;
    uint256 public endBlock;
    string ipfsHash;
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    address public highestBidder;
    
    mapping(address => uint) public bids;
    uint bidIncrement;
    
    constructor(address creator) public {
        owner = creator;
        startBlock = block.number;
        endBlock = startBlock +3; // 720; // 3 min
        ipfsHash = "";
        auctionState = State.Running;
        
        bidIncrement = 1000000000000000000; //1 ether
        
        highestBindingBid = 0;
    }
    
    function getCurrentBlock() public view  returns(uint){
        return block.number;
    }
    modifier afterStart(){
        require(block.number >= startBlock, "afterStart");
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock, "beforeEnd");
        _;
    }
    
    modifier onlyOwner(){
        require(owner != msg.sender, "notOwner");
        _;
    }
    
    modifier notOwner(){
        require(owner != msg.sender, "notOwner");
        _;
    }
    

    modifier notHighestBidder(){
        require(highestBidder != msg.sender,"notHighestBidder" );
        _;
    }
    
    function min(uint a, uint b) pure private returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    function cancelAuction() public onlyOwner
    {
        auctionState = State.Canceled;
    }
    
    function placeBid() public payable afterStart beforeEnd notOwner  notHighestBidder returns(bool){
        require(auctionState == State.Running, "auctionState == State.Running");
        require(msg.value > 0.001 ether, "msg.value > 0.001 ether");
        
        uint currentBid = bids[msg.sender] + msg.value;
                 //50           //30
        require(currentBid > highestBindingBid);
                            
        bids[msg.sender] = currentBid;
        
            //20           //100
        if(currentBid <= bids[highestBidder]){
                                                //30                  //100
            highestBindingBid = min (currentBid + bidIncrement, bids[highestBidder]);
        }else{                          //20            //10
            highestBindingBid = min (currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = msg.sender;
        }
        
        return true;
    }
    
    function finalize() payable public {
        require(auctionState == State.Canceled || block.number > endBlock);
        
        require(msg.sender == owner || bids[msg.sender] > 0, "no ether for current address");
        
        address recepient;
        uint value;
        
        if(auctionState == State.Canceled){
            recepient = msg.sender;
            value = bids[msg.sender];
        }else{//ended time
            if(msg.sender == owner){
                recepient = msg.sender;
                value = highestBindingBid;
            }else{
                if(msg.sender == highestBidder){
                    recepient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{//this is nether the owner nor the highest bidder
                      recepient = msg.sender;
                      value = bids[msg.sender];
                }
            }
        }
        
        bids[msg.sender] = 0;
        
        recepient.transfer(value);
        
    }
}