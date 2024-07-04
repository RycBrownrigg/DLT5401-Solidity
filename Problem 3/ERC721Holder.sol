// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtNFT is ERC721, Ownable { // Inherit from Ownable contract to use onlyOwner modifier for mintNFT function 
    using Counters for Counters.Counter; // Import Counters library to use Counter data structure 
    Counters.Counter private _tokenIds;  // Declare a private variable to store tokenIds

    constructor() ERC721("ArtNFT", "ART") {} // Constructor to set name and symbol of NFT 

    function mintNFT(address recipient) public onlyOwner returns (uint256) { // Function to mint NFT and return the tokenId of the NFT minted
        _tokenIds.increment(); // Increment the value of tokenIds
        uint256 newItemId = _tokenIds.current(); // Get the current value of tokenIds
        _mint(recipient, newItemId); // Mint the NFT with tokenId newItemId and send it to recipient address 
        return newItemId; // Return the tokenId of the NFT minted
    }
}