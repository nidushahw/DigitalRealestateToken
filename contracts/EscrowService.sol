// SPDX-License-Identifier: MIT


pragma solidity ^0.7.1;

contract EscrowService {
    
    address public owner;
    
    enum State { PAYMENT_DONE, DELIVERED, RELEASED, REFUNDED }
    
    struct EscrowInfo {
        uint trnxId;
        address payable buyer;
        address payable seller;
        address payable agent;
        uint8 fee;
        uint amount;
        State state;
    }
    
    struct TransactionInfo {
       uint trnxId;
       address buyer; 
    }
    
    mapping(address => EscrowInfo[]) private buyers;
    
    mapping(address => uint8) public escrowFee;
    
    mapping(address => TransactionInfo[]) private agents;
    
    constructor() {
        owner = msg.sender;
    }
    
    function setEscrowFee(uint8 fee) public {
        require (fee >= 1 && fee < 100, "Invalid Fee");
        escrowFee[msg.sender] = fee;
    }
    
    function addEscrow(address payable _seller, address payable _agent) public payable returns (uint) {
        require(_seller != address(0), "Invalid Seller");
        require(_agent != address(0), "Invalid agent");
        require(msg.value > 0);
        uint8 _fee = escrowFee[_agent];
        require(_fee >= 1, "Unregistered Agent");
        uint trnxId = buyers[msg.sender].length;
        EscrowInfo memory escrowInfo;
        escrowInfo.trnxId = trnxId;
        escrowInfo.buyer = msg.sender;
        escrowInfo.seller = _seller;
        escrowInfo.agent = _agent;
        escrowInfo.fee = _fee;
        escrowInfo.amount = msg.value;
        escrowInfo.state = State.PAYMENT_DONE;
        buyers[msg.sender].push(escrowInfo);
        
        TransactionInfo memory transactionInfo;
        transactionInfo.buyer = msg.sender;
        transactionInfo.trnxId = trnxId;
        agents[_agent].push(transactionInfo);
  
        return trnxId;
    }
    
    function confirmDelivery(uint _trnxId) public {
        require(buyers[msg.sender].length > _trnxId, "Invalid Transaction ID");
        EscrowInfo memory escrowInfo = buyers[msg.sender][_trnxId];
        require(escrowInfo.buyer == msg.sender, "Escrow does not exists!");
        require(escrowInfo.state == State.PAYMENT_DONE, "Payment is not yet made");
        buyers[msg.sender][_trnxId].state = State.DELIVERED;
    }
    
    function releasePayment(address _buyer, uint _trnxId) public {
        require(buyers[_buyer].length > _trnxId, "Invalid Transaction ID");
        EscrowInfo memory escrowInfo = buyers[_buyer][_trnxId];
        require(escrowInfo.agent == msg.sender, "Not a valid agent");
        require(escrowInfo.state == State.DELIVERED, "Delevery is not yet done");
        buyers[_buyer][_trnxId].state = State.RELEASED;
        escrowInfo.seller.transfer((escrowInfo.amount * (100 - escrowInfo.fee))/100);
        escrowInfo.agent.transfer((escrowInfo.amount * escrowInfo.fee)/100);
    }
    
    function refundPayment(address _buyer, uint _trnxId) public {
        require(buyers[_buyer].length > _trnxId, "Invalid Transaction ID");
        EscrowInfo memory escrowInfo = buyers[_buyer][_trnxId];
        require(escrowInfo.agent == msg.sender, "Not a valid agent");
        require(escrowInfo.state == State.PAYMENT_DONE, "Payment is not yet made or already settled");
        buyers[_buyer][_trnxId].state = State.REFUNDED;
        escrowInfo.buyer.transfer((escrowInfo.amount * (100 - escrowInfo.fee))/100);
        escrowInfo.agent.transfer((escrowInfo.amount * escrowInfo.fee)/100);
    }
    
    function getEscrowCountForBuyer() public view returns (uint) {
        return buyers[msg.sender].length;
    }
    
    function getEscrowByTrnxId(address _buyer, uint _trnxId) public view returns(uint trnxId, address buyer, address seller, address agent, uint amount, uint8 fee, State state) {
        require(buyers[_buyer].length > _trnxId, "Invalid Transaction ID");
        EscrowInfo memory escrowInfo = buyers[_buyer][_trnxId];
        require(escrowInfo.buyer == msg.sender || escrowInfo.seller == msg.sender || escrowInfo.agent == msg.sender, "Unauthorized");
        return (escrowInfo.trnxId, escrowInfo.buyer, escrowInfo.seller, escrowInfo.agent, escrowInfo.amount, escrowInfo.fee, escrowInfo.state);
    }
    
    function getTransactionsCountForAgent() public view returns (uint) {
        return agents[msg.sender].length;
    }
    
    function getTransactionByIndex(uint _index) public view returns(uint trnxId, address buyer, address seller, address agent, uint amount, uint8 fee, State state) {
        require(agents[msg.sender].length > _index, "Invalid Transaction Index");
        TransactionInfo memory transactionInfo = agents[msg.sender][_index];
        EscrowInfo memory escrowInfo = buyers[transactionInfo.buyer][transactionInfo.trnxId];
        return (escrowInfo.trnxId, escrowInfo.buyer, escrowInfo.seller, escrowInfo.agent, escrowInfo.amount, escrowInfo.fee, escrowInfo.state);
    }
    
}