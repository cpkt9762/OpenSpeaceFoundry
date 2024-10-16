// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/NftMarket.sol";
import "../src/MyERC721NFT.sol";
import "../src/Erc20Token.sol";
contract NftMarketTest is Test {
    NFTMarket nftMarket;
    MyERC20Token token;
    MyERC721NFT nft;
     uint256 nftId;
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia"); 
        token = new MyERC20Token();
        nft = new MyERC721NFT();
        nftId= nft.mintNFT("https://www.google.com/ipfs/1");
        nftMarket=new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);

    } 
    //测试修改价格
    function test_list() public {
        nftMarket.list(0, 100); 
    }
 
}