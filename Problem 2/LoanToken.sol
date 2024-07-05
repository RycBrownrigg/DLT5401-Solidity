/*
 LoanToken

 of an ERC-20 token.
 
This contract implements the basic functionality of an ERC-20 token called "LoanToken" with the symbol "LOAN". It includes the standard functions for transferring tokens, approving spending by third parties, and delegating transfers. The contract is initialized with an initial supply of tokens, which are assigned to the contract deployer. Users can transfer tokens to other addresses, approve other addresses to spend tokens on their behalf, and allow approved addresses to transfer tokens on their behalf.

Here's an overview of what the contract does:

1.	Contract Declaration: 
 	- Defines a contract named "LoanToken"
 	- Sets the SPDX license identifier and Solidity version
2.	Token Properties: 
 	- name: "LoanToken"
 	- symbol: "LOAN"
 	- decimals: 18 (standard for most ERC-20 tokens)
 	- totalSupply: stores the total number of tokens
3.	State Variables: 
 	- balanceOf: a mapping to track token balances for each address
 	- allowance: a nested mapping to track approved token amounts for spending by third parties
4.	Events: 
 	- Transfer: emitted when tokens are transferred
 	- Approval: emitted when an address approves another to spend tokens on its behalf
5.	Constructor: 
 	- Initializes the contract with an initial supply of tokens
 	- Assigns all initial tokens to the contract deployer
6.	Functions: 
    a. transfer: 
 	 -  Allows users to send tokens to another address
 	 -  Checks for sufficient balance before transferring
 	 -  Updates balances and emits a Transfer event
    b. approve: 
 	 -  Allows users to approve another address to spend a certain amount of their tokens
 	 -  Updates the allowance mapping and emits an Approval event
    c. transferFrom: 
 	 -  Allows an approved address to transfer tokens on behalf of the token owner
 	 -  Checks for sufficient balance and allowance before transferring
 	 -  Updates balances and allowances, and emits a Transfer event

This contract implements the basic functionality of an ERC-20 token, including transfers, approvals, and delegated transfers. 



 */


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Solidity version

contract LoanToken { // Contract name 
    string public name = "LoanToken"; // Token name LoanToken - public string type
    string public symbol = "LOAN"; // Token symbol LOAN - public string type
    uint8 public decimals = 18; // Token decimals 18 - public uint8 type
    uint256 public totalSupply; // totalSupply of tokens - public uint256 type
    mapping(address => uint256) public balanceOf; // Mapping of address to balanceOf - public mapping type
    mapping(address => mapping(address => uint256)) public allowance; // Mapping of address to mapping of address to allowance - public mapping type

    event Transfer(address indexed from, address indexed to, uint256 value); // Transfer event - indexed from, to, value - public event type 
    event Approval(address indexed owner, address indexed spender, uint256 value); // Approval event - indexed owner, spender, value - public event type

    constructor(uint256 initialSupply) { // Constructor function with initialSupply parameter - public visibility 
        totalSupply = initialSupply; // totalSupply is assigned to initialSupply 
        balanceOf[msg.sender] = initialSupply; // balanceOf[msg.sender] is assigned to initialSupply 
    }

    function transfer(address to, uint256 value) public returns (bool success) { // Transfer function with to, value parameters - public visibility 
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // Check if balance of sender is greater than or equal to value
        balanceOf[msg.sender] -= value; // Deduct value from sender's balance 
        balanceOf[to] += value; // Add value to receiver's balance 
        emit Transfer(msg.sender, to, value); // Emit Transfer event 
        return true; // Return true
    }

    function approve(address spender, uint256 value) public returns (bool success) { // approve function with spender, value parameters - public visibility 
        allowance[msg.sender][spender] = value; //allows the msg.sender to give permission to the spender to transfer up to value amount of tokens
        emit Approval(msg.sender, spender, value); // Emit Approval event 
        return true; // Return true
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) { // transferFrom function with from, to, value parameters - public visibility 
        require(balanceOf[from] >= value, "Insufficient balance"); // require balance of from is greater than or equal to value. If not, revert and show error message
        require(allowance[from][msg.sender] >= value, "Insufficient allowance"); // require allowance of from to msg.sender is greater than or equal to value. If not, revert and show error message
        balanceOf[from] -= value; // Deduct value from sender's balance
        balanceOf[to] += value; // Add value to receiver's balance
        allowance[from][msg.sender] -= value; // Deduct value from allowance of from to msg.sender
        emit Transfer(from, to, value); // Emit Transfer event
        return true; // Return true
    }
}