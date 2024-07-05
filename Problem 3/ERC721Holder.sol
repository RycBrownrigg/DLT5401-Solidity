/*
This smart contract implements an NFT (Non-Fungible Token) using the ERC721 standard. 

Here's an overview of the contract and how to use it:

Contract Overview:

-	The contract is named `ArtNFT` and inherits from OpenZeppelin's `ERC721` and `Ownable` contracts.
-	It uses Solidity version 0.8.0 or higher.
-	The contract keeps track of the current token ID using a private variable `_currentTokenId`.

Key Components:

1.	Constructor:
-	Initializes the ERC721 token with the name "ArtNFT" and symbol "ART".
-	Sets the contract owner to the address deploying the contract.
-	Initializes `_currentTokenId` to 0.

2.	mintNFT function:
-	Allows the contract owner to mint new NFTs.
-	Increments the `_currentTokenId` and mints a new token to the specified recipient.
-	Returns the new token ID.

3.	getCurrentTokenId function:
-	A public view function that returns the current token ID.

How to Use the Contract:

1.	Deploy the contract.
-	The deploying address will become the contract owner.

2.	Minting NFTs:
-	Only the contract owner can mint new NFTs.
-	Call the `mintNFT` function, providing the recipient's address as an argument.
-	This will mint a new NFT to the specified address and return the new token ID.

3.	Checking Current Token ID:
-	Anyone can call the `getCurrentTokenId` function to see the ID of the last minted token.

4.	Standard ERC721 Functions:
-	All standard ERC721 functions like `transfer`, `approve`, `balanceOf`, etc., are available.

5.	Ownership:
-	The contract inherits from Ownable, so ownership functions like `transferOwnership` are available to the current owner.

Overall, this contract provides a simple implementation of an NFT with minting functionality and ownership control.

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // Solidity version 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Import ERC721 contract from OpenZeppelin
import "@openzeppelin/contracts/access/Ownable.sol"; // Import Ownable contract from OpenZeppelin

contract ArtNFT is ERC721, Ownable { // Contract name ArtNFT - ERC721, Ownable inheritance 
    uint256 private _currentTokenId; // Private variable _currentTokenId - uint256 type

    constructor() ERC721("ArtNFT", "ART") Ownable(msg.sender) { // Constructor function with ERC721, Ownable inheritance - public visibility. 
        _currentTokenId = 0; // Initialize _currentTokenId to 0
    }

    function mintNFT(address recipient) public onlyOwner returns (uint256) { // mintNFT function with recipient parameter - public onlyOwner visibility. Returns uint256. 
        _currentTokenId++;
        uint256 newItemId = _currentTokenId;
        _mint(recipient, newItemId);
        return newItemId;
    }

    function getCurrentTokenId() public view returns (uint256) { // getCurrentTokenId function - public view visibility. Returns uint256. 
        return _currentTokenId;
    }
}