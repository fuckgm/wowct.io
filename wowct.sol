pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// WOWCT contract
// ----------------------------------------------------------------------------
contract WOWCT {
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    uint256 private constant FLAG_IS_POSITIVE = 1 << 128;
    uint128 constant internal BASE = 10 ** 18;

    /**
     * @notice Bounding params constraining updates to the funding rate.
     *
     *  Like the funding rate, these are per-second rates, fixed-point with 18 decimals.
     *  We calculate the per-second rates from the market specifications, which uses 8-hour rates:
     *  - The max absolute funding rate is 0.75% (8-hour rate).
     *  - The max change in a single update is 0.75% (8-hour rate).
     *  - The max change over a 55-minute period is 0.75% (8-hour rate).
     *
     *  This means the fastest the funding rate can go from zero to its min or max allowed value
     *  (or vice versa) is in 55 minutes.
     */
    uint128 public constant MAX_ABS_VALUE = BASE * 75 / 10000 / (8 hours);
    uint128 public constant MAX_ABS_DIFF_PER_UPDATE = MAX_ABS_VALUE;
    uint128 public constant MAX_ABS_DIFF_PER_SECOND = MAX_ABS_VALUE / (55 minutes);
    uint128 public Types;
  
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function initTypes()public onlyOwner{
        Types.push(Type(50000000000000000000,'CN-01',1));
        Types.push(Type(100000000000000000000,'AA-12',1));
        Types.push(Type(150000000000000000000,'M82A1',1));
        Types.push(Type(500000000000000000000,'RB123',1));
        Types.push(Type(1000000000000000000000,'AN602',1));
        Types.push(Type(1500000000000000000000,'SD-216',1));
    }
    
    function setRound(uint32 _round)public onlyOwner{
        require(_round==0||_round==1||_round==2||_round==3||_round==4);
        if(_round==1){
            require(fpsRewardTotal>=fpsTotalSupply*51/100*51/100);
            erc20Interface =  Erc20Interface(fpsContract);
            rounds[_round] = Round(fpsContract,fpsContract);
        }else if(_round==2){
            require(fpsRewardTotal>=fpsTotalSupply*51/100);
            erc20Interface =  Erc20Interface(ppsContract);
            rounds[_round] = Round(fpsContract,ppsContract);
        }else if(_round==3){
            require(ppsRewardTotal>=ppsTotalSupply*51/100);
            erc20Interface =  Erc20Interface(pssContract);
            rounds[_round] = Round(pssContract,pssContract);
        }else if(_round==4){
            require(pssRewardTotal>=pssTotalSupply*51/100*51/100);
            erc20Interface =  Erc20Interface(sssContract);
            rounds[_round] = Round(pssContract,sssContract);
        }else{
             erc20Interface =  Erc20Interface(fpsContract);
             rounds[_round] = Round(usdtContract,fpsContract);
        }
        nowRound = _round;
    }
    
    function updateRound()public{
        if(pssRewardTotal>=pssTotalSupply*51/100*51/100){
            erc20Interface =  Erc20Interface(sssContract);
            nowRound = 4;
        }else if(ppsRewardTotal>=ppsTotalSupply*51/100){
            erc20Interface =  Erc20Interface(pssContract);
            nowRound = 3;
        }else if(fpsRewardTotal>=fpsTotalSupply*51/100){
            erc20Interface =  Erc20Interface(ppsContract);
            nowRound =2;
        }else if(fpsRewardTotal>=fpsTotalSupply*51/100*51/100){
            erc20Interface =  Erc20Interface(fpsContract);
            nowRound =1;
        }else{
            erc20Interface =  Erc20Interface(fpsContract);
            nowRound =0;
        }
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
