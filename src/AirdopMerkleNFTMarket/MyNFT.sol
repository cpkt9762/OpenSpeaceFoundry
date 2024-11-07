// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
contract MyERC721NFT is ERC721URIStorage {
    uint256 private _tokenIdCounter;
    // Base URI for NFT metadata
    string private _baseTokenURI;
    address public owner;
    constructor() ERC721("PingZI", "SXNFT") {
        owner = msg.sender;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }  
 
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function safeMint(address receiver) public onlyOwner {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(receiver, tokenId);
        _tokenIdCounter += 1;
    }

    function mintNFT(string memory tokenURI) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter; 

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
         _tokenIdCounter += 1;
        return tokenId;
    }
 
}
 