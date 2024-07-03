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