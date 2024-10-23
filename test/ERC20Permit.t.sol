// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/TokenBank.sol";
import "../src/MyERC721NFT.sol";
import "../src/NftMarket.sol";
import {console} from "forge-std/console.sol";


contract TokenBankTest is Test {
    MyToken public myToken;
    TokenBank public tokenBank;
    MyERC721NFT public myNFT;
    NftMarket public nftMarket;
    address public owner;
    address public user1; 
    uint256 private ownerPrivateKey;
    uint256 public nftidId;
    function setUp() public {
        // Generate owner's private key    
        ownerPrivateKey = uint256(keccak256(abi.encodePacked("owner")));
        // Generate owner's address
        owner = vm.addr(ownerPrivateKey);
        // Generate user1's address
        user1 = address(0x1);
        // Deploy MyToken contract
        myToken = new MyToken();
        
        // Deploy TokenBank contract
        tokenBank = new TokenBank(address(myToken));

        // Deploy MyERC721NFT contract
        myNFT = new MyERC721NFT();
        
        nftidId = myNFT.mintNFT(
            "https://sapphire-familiar-toucan-190.mypinata.cloud/ipfs/QmWoSUtP6FLVTqfAcBd7RVjNwfVdGAtaUqYDTEsK3LGgyi"
        );
        // Deploy NftMarket contract
        nftMarket = new NftMarket(address(myNFT), address(myToken)); 
        // Transfer some initial tokens to user1
        myToken.transfer(user1, 1000 ether);

    }

    function test_Deposit() public {
        uint256 amount = 100 * 10 ** myToken.decimals();
        vm.deal(owner, 1000 ether);
        deal(address(myToken), owner, amount); 
        // First authorize the TokenBank contract
        vm.prank(owner);
        myToken.approve(address(tokenBank), amount);

        // Call TokenBank's deposit function
        vm.prank(owner);
        tokenBank.deposit(amount);

        // Check the balance of the TokenBank contract and the user's deposit
        assertEq(myToken.balanceOf(address(tokenBank)), amount);
        assertEq(tokenBank.balances(owner), amount);
     }

    
    // Test Token deposit 
    function test_PermitDeposit() public {
        uint256 amount = 100 * 10 ** myToken.decimals();
        uint256 nonce = myToken.nonces(owner);
        uint256 deadline = block.timestamp + 1 days; 

        // Give owner some tokens
        vm.deal(owner, 1000 ether); 
        deal(address(myToken), owner, amount);   

        // First authorize the TokenBank contract
        vm.prank(owner);
        myToken.approve(address(tokenBank), amount); 

        // Generate the permit's hash  
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(owner, ownerPrivateKey, address(tokenBank), amount, deadline, nonce); 
        
        // Call TokenBank's permitDeposit function 
        vm.prank(owner);
        tokenBank.permitDeposit(amount, deadline, v, r, s);

        // Check the balance of the TokenBank contract and the user's deposit
        assertEq(myToken.balanceOf(address(tokenBank)), amount);
        assertEq(tokenBank.balances(owner), amount);
    }
   // Test NFT purchase 
    function test_PermitBuy() public { 
        uint256 amount = 100 ether;
        uint256 price = 10;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = myToken.nonces(owner); 
        bytes32 hash = keccak256(abi.encodePacked(owner, nftidId, amount, deadline, nonce));
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(ownerPrivateKey, hash);
        address signer = ecrecover(hash, v1, r1, s1); 
        assert(signer == owner);

        // Give owner some tokens
        vm.deal(owner, 1000 ether); 
        deal(address(myToken), owner, amount * price);   
        
        // Add owner to the whitelist
        nftMarket.addToWhitelist(owner);
 
      
        // Owner authorizes tokens
        vm.prank(owner);
        myToken.approve(address(nftMarket), amount); 
        myNFT.approve(address(nftMarket), nftidId); 
        nftMarket.list(nftidId, price);

        // Call permitBuy
        vm.prank(owner);
        nftMarket.permitBuy(nftidId, amount, deadline, nonce, v1, r1, s1);

       // Check if the NFT has been transferred to user1
       assertEq(myNFT.ownerOf(nftidId), owner);
    }

    // Helper function to get the permit signature
    function _getPermitSignature(
        address  ow,
        uint256 ow_private_key,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 nonce
    ) internal returns (uint8 v, bytes32 r, bytes32 s) { 
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                myToken.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(
                    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                    ow,
                    spender,
                    value,
                    nonce,
                    deadline
                ))
            )
        ); 
        (v, r, s) = vm.sign(ow_private_key, digest);
       
        return (v, r, s);
    }
}
