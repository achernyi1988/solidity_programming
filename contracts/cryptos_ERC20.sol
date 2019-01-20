pragma solidity ^0.4.24;



contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CryptosToken is ERC20Interface{
    
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0;
    
    uint public supply;
    address public founder;
    
    mapping (address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    constructor() public{
        supply = 1000000; //1 milion
        founder = msg.sender;
        
        balances[founder] = supply;
    }    
    
    function totalSupply() public view returns (uint){
            return supply;
    }
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens && tokens > 0,"balances[msg.sender] >= tokens && tokens > 0");
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];    
    }
    function approve(address spender, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens, "balances[msg.sender] >= tokens");
        require(tokens > 0, "tokens > 0");
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens );
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(allowance(from, to) >= tokens, "allowance(from, to) >= tokens");
        require(balances[from] >= tokens,"balances[from] >= tokens");
        
        balances[from] -= tokens;
        balances[to]   += tokens;
        allowed[from][to] -= tokens;
        
        return true;
    }
    
}



contract CryptosICO is  CryptosToken{
    address public admin;
    address public deposit;
    
    //token prce in wei: 1 CRTP = 0.001 ETHER; 1 ETHER = 1000 CRPT
    
    uint tokenPrice = 1000000000000000;
    
    uint minimumInvestment = 1000000000000000;
    uint maximumInvestment = 8000000000000000000;
    
    uint startedTime = now;
    uint stoppedTime = startedTime + 3600; // 1 min
    uint coinTradeStart = 36000;// transerable in 10 min after finish
    
    uint hardCap = 20000000000000000000; // 20 ether
    
    uint public raisedAmount;
    enum State {beforeStarted, running, afterStopped, halted}
    
    State ico_state;
    
    event Invest(address from,uint value, uint token);
    
    constructor(address _deposit) public{
        ico_state = State.beforeStarted;
        deposit = _deposit;
        admin = msg.sender;
    }
    
    function halt() public {
        ico_state = State.halted;
    }
    
    function unhalt() public {
        ico_state = State.running;
    }
    
    function getCurrentState() private view returns(State){
        if(ico_state == State.halted)
        {
            return State.halted;
        }else if(startedTime <= now && now <= stoppedTime){
            return State.running;
        }
        else if(now > stoppedTime){
            return State.afterStopped;
        }else{
            return State.beforeStarted;
        }
    }
    

    function changedDepositAddress(address _deposit) public onlyAdmin{
        deposit = _deposit;
    }
    
    function invest() public payable {
        require(minimumInvestment <= msg.value && msg.value <= maximumInvestment,
               "minimumInvestment <= msg.value && msg.value <= maximumInvestment");
                
        require(State.running == getCurrentState(), "State.running == getCurrentState()");
        uint token = msg.value / tokenPrice;
        
        //hardCap
        require(raisedAmount + msg.value <= hardCap );
        require(token <= balances[founder], "token <= balances[founder]");
        
        balances[founder] -= token;
        balances[msg.sender] += token;
        
        raisedAmount += msg.value;
        
        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, token);
        
    }
    
    function burn() public onlyAdmin{
        require(getCurrentState() == State.afterStopped);
        balances[founder] = 0;
    }
    
    function() public payable {
        invest();
    }
    
    function transfer(address to, uint tokens) public returns (bool ){
         require(now > coinTradeStart, "now > coinTradeStart");
         return super.transfer(to, tokens);
    }
    
     function transferFrom(address from, address to, uint tokens) public returns (bool success){
         require(now > coinTradeStart);
         return super.transferFrom(from, to, tokens);
     }
        
        
    modifier onlyAdmin() {
        require(msg.sender == admin, "msg.sender == admin");
        _;
    }
}
