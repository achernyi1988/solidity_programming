pragma solidity ^0.4.24;

contract FundRaising
{
	mapping (address =>uint256) public contributors;
	
	address public admin;
	
	uint256 public noOfContributors;
	uint256 public minimumContribution;
	
	uint256 public deadline; //this is a timestamp
	uint256 public goal; 
	
	uint256 public raisedAmount = 0;
	
	struct Request{
		string description;
		address recipient;
		uint256 value;
		bool complited;
		uint256 noOfVoters;
		mapping(address => bool) votes;
	}

	Request [] public requests;
	
	
	event ContributeEvent(address _sender, uint256 _value);
	event CreateRequetsEvent(string _descriptiontion, address _recipient, uint256 _value);
	event ApproveEvent(address _recipient, uint256 _value);
	
	constructor(uint256 _goal, uint256 _deadline) public{
		admin = msg.sender;
		
		deadline = now + _deadline;
		goal = _goal;
		minimumContribution = 10;
	}
	
	function contribute()public payable{
		require(now < deadline, "now < deadline");
		require(msg.value >= minimumContribution, "msg.value >= minimumContribution");
		
		if(contributors[msg.sender] == 0){
		   noOfContributors++;
		}
		
		contributors[msg.sender] +=msg.value;
		
		raisedAmount += msg.value;
		emit ContributeEvent(msg.sender, msg.value);
	} 
	
	function getBalance() public view returns(uint256){
		return address(this).balance;
	}
	
	function getRefund() public payable{
		require(now > deadline, "now > deadline");
		require(raisedAmount < goal, "raisedAmount < goal");
		require(contributors[msg.sender] > 0,"contributors[msg.sender] > 0");
		
		
		//--------------option----------------//
		noOfContributors--;
		raisedAmount -=contributors[msg.sender];
		//------------------------------//
	 
		msg.sender.transfer(contributors[msg.sender]);
		contributors[msg.sender] = 0;
	
	}



	function createRequest(string _description, address _recipient, uint256 _value) public isAdminRequired(true) {
		
		Request memory newRequest = Request({
			description: _description,
			recipient: _recipient,
			value: _value,
			complited: false,
			noOfVoters:0
		});
		
		requests.push(newRequest);
		
		emit CreateRequetsEvent(_description, _recipient, _value);
	}
	
	function voteRequest(uint256 index) public isAdminRequired(false){
		
	 
		require(contributors[msg.sender] > 0, "contributors[msg.sender] > 0");
		Request storage request = requests[index];
		  
		require(!request.votes[msg.sender], "already voted");
		
		request.noOfVoters++;
		request.votes[msg.sender] = true;
	}
	
	function Approve(uint256 index) public isAdminRequired(true) isRangeRequests (index){
		
		  Request storage request = requests[index];
		  require(request.complited == false, "request.complited == false");
		  
		  // request.complited = ((noOfContributors * 10 /2) > noOfContributors  * 10 - request.noOfVoters * 10); 
					 
		  require(request.noOfVoters > noOfContributors/2, "less than 50 % voted"); 
		  
		  request.recipient.transfer(request.value);
		  
		  request.complited = true;
		  
		  emit ApproveEvent(request.recipient,request.value );
	}
	
	modifier isRangeRequests(uint256 index){
		   require(0 <= index &&  index < requests.length);
		_;
	}
	
	modifier isAdminRequired(bool who){
		
		if(who)
			require(msg.sender == admin,"msg.sender == admin" );
		else
			require(msg.sender != admin, "msg.sender != admin");
		_;
	}
	
	modifier notAdmin(){
		require(msg.sender != admin);
		_;
	}
}