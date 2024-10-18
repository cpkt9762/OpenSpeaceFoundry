// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/NftMarket.sol";
import "../src/MyERC721NFT.sol";
import "../src/Erc20Token.sol";
/*要求测试内容： 
上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
 */

contract NftMarketTest is Test {
    NFTMarket nftMarket;
    MyERC20Token token;
    MyERC721NFT nft;
    uint256 nftId;
    address user = address(0x7D85Cf6dd28C89095E540e31E3Bf90e965073Ea4);

    // NFT被挂牌时触发的事件
    event NFTListed(uint256 indexed nftId, address indexed seller, uint256 price);

    // NFT被购买时触发的事件
    event NFTBought(uint256 indexed nftId, address indexed buyer, uint256 price);

    function setUp() public {
        token = new MyERC20Token();
        nft = new MyERC721NFT();
        nftId = nft.mintNFT(
            "https://sapphire-familiar-toucan-190.mypinata.cloud/ipfs/QmWoSUtP6FLVTqfAcBd7RVjNwfVdGAtaUqYDTEsK3LGgyi"
        );
    }

    //上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
    function test_list() public {
        nftMarket = new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);
        // 测试上架成功
        vm.expectEmit(true, true, false, true);
        emit NFTListed(nftId, address(this), 100); // 假设价格为 100 Token
        nftMarket.list(nftId, 100);
        (,, bool isListed) = nftMarket.listings(nftId);
        assertEq(isListed, true, "NFT is not listed");

        // 测试重复上架的失败
        vm.expectRevert("NFT is already listed");
        nftMarket.list(nftId, 100);
    }

    //购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
    //1 测试购买成功
    function test_buy1() public {
        nftMarket = new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);
        // 上架 NFT
        nftMarket.list(nftId, 100);
        deal(address(token), user, 1000000000);
        vm.prank(user);
        token.approve(address(nftMarket), 100);
        vm.expectEmit(true, true, false, true);
        emit NFTBought(nftId, user, 100);
        nftMarket.buyNFT(user, 100, nftId);
        assertEq(nft.ownerOf(nftId), user, "NFT should belong to user2");
        assertEq(token.balanceOf(user), 999999900, "User2 should have 999999900 tokens");
    }

    //2 自己购买自己的NFT
    function test_buy2() public {
        nftMarket = new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);
        // 上架 NFT
        nftMarket.list(nftId, 100);
        vm.expectRevert("You cannot buy your own NFT");
        nftMarket.buyNFT(address(this), 100, nftId);
    }

    //3 NFT被重复购买
    function test_buy3() public {
        nftMarket = new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);
        vm.prank(user);
        token.approve(address(nftMarket), 100);

        // 上架 NFT
        nftMarket.list(nftId, 100);
        deal(address(token), user, 100000000000);

        nftMarket.buyNFT(user, 100, nftId);

        vm.expectRevert("NFT not listed");
        nftMarket.buyNFT(user, 100, nftId);
    }

    //4 支付Token过多
    function test_buy4() public {
        nftMarket = new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);
        vm.prank(user);
        token.approve(address(nftMarket), 100);
        // 上架 NFT
        nftMarket.list(nftId, 100);
        deal(address(token), user, 100000000000);

        vm.expectRevert("Insufficient token amount to buy NFT");
        nftMarket.buyNFT(user, 100000000000, nftId);
    }

    //5 支付Token不足
    function test_buy5() public {
        nftMarket = new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);
        vm.prank(user);
        token.approve(address(nftMarket), 100);

        // 上架 NFT
        nftMarket.list(nftId, 100);
        deal(address(token), user, 1);

        vm.expectRevert("Insufficient token amount to buy NFT");
        nftMarket.buyNFT(user, 1, nftId);
    }

    //模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    /// forge-config: default.fuzz.runs = 100
    function test_fuzz_buy(uint256 price, address buyer) public {
        vm.assume(buyer != address(0));
        price = bound(price, 0.01 ether, 10000 ether);
        vm.assume(price > 0.01 ether && price < 10000 ether);

        nftMarket = new NFTMarket(address(nft), address(token));
        nft.approve(address(nftMarket), nftId);
        nftMarket.list(nftId, price);

        vm.prank(buyer);
        token.approve(address(nftMarket), price);
        deal(address(token), buyer, price);

        // 购买NFT
        vm.expectEmit(true, true, false, true);
        emit NFTBought(nftId, buyer, price);
        nftMarket.buyNFT(buyer, price, nftId);

        assertEq(nftMarket.getNFTPrice(nftId), price);
    }

    //不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    // 不可变测试
    function invariant_noTokenHoldings() public view {
        uint256 contractBalance = token.balanceOf(address(nftMarket));
        assertEq(contractBalance, 0, "NFTMarket should not hold any Tokens");
    }
}
