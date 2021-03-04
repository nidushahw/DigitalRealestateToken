pragma solidity >=0.7.0 <0.8.0;

contract NestedMapping {

    struct balance {
        uint timestamp;
        uint amount;
    }

    mapping(address => mapping(uint => balance)) accountOwner;
    
    function createAccount(uint accountNumber) public {
        accountOwner[msg.sender][accountNumber] = balance(block.timestamp, 0);
    }

    function getAccountBalance(uint accountNumber) public view returns (uint timestamp, uint amount) {
        return (accountOwner[msg.sender][accountNumber].timestamp, accountOwner[msg.sender][accountNumber].amount);
    }

    function getDateLastAccountUpdate(uint accountNumber) public view returns (uint) {
        // write the return code to return the timestamp of a an account owned by msg.sender
    }
    
    function recordDeposit(uint accountNumber, uint deposit) public returns (uint newBalance) {
        // Write code here to update the amount in an account owned by the msg.sender by adding the deposit
        
        // return the new balance in the account
        return accountOwner[msg.sender][accountNumber].amount;
    }
    
    function recordWithdrawl(uint accountNumber, uint withrdawl) public returns (uint NewBalance) {
        // Write code here to update the amount in an account owned by the msg.sender by subtracting the withdrawl
        
        // write the code to return the new balance in the account
        
    }
}