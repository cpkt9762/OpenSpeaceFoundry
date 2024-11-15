// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/NftMarket.sol";
import "../src/MyERC721NFT.sol";
import "../src/Erc20Token.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NftMarketTest is Test {
    NftMarket nftMarket;
    MyERC721NFT nft;
    uint256 nftId;
    address user;
    uint256 userPk;
    address user2;
    uint256 userPk2;
    // NFT被挂牌时触发的事件

    event NFTListed(uint256 indexed nftId, address indexed seller, uint256 price);

    // NFT被购买时触发的事件
    event NFTBought(uint256 indexed nftId, address indexed buyer, uint256 price);

    function setUp() public {
        (user, userPk) = makeAddrAndKey("alice");
        (user2, userPk2) = makeAddrAndKey("bob");

        nft = new MyERC721NFT();
        vm.prank(user);
        nftId = nft.mintNFT("https://sapphire-familiar-toucan-190.mypinata.cloud");
        vm.prank(user);
        nftMarket = new NftMarket(address(user));

        vm.prank(user);
        nft.approve(address(nftMarket), nftId);
    }

    //1 测试通过token上架和购买
    function test_list_and_buy1() public {
        Erc20Token token = new Erc20Token();
        uint256 price = 100;
        uint256 deadline = block.timestamp + 1 days;
        ListOrder memory order =
            ListOrder({nft: address(nft), tokenId: nftId, payToken: address(token), price: price, deadline: deadline});
        bytes32 domainSeparator = nftMarket.buildDomainSeparator();
        bytes32 orderId = nftMarket.orderHash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, MessageHashUtils.toTypedDataHash(domainSeparator, orderId));
        bytes memory signature = abi.encodePacked(r, s, v);
        address signer = ECDSA.recover(MessageHashUtils.toTypedDataHash(domainSeparator, orderId), signature);
        assertEq(signer, address(user), "Invalid signature");

        assertEq(nft.ownerOf(nftId), user, "NFT should belong to user");

        // 上架 NFT
        vm.prank(user);
        nftMarket.listNFT(order, signature);

        // 获取订单ID
        bytes32 orderId2 = nftMarket.listing(address(nft), nftId);
        assertEq(orderId2, orderId, "Order ID should match");

        // 给用户2一些Token
        vm.deal(user, 1000 ether);
        vm.deal(user2, 1000 ether);
        vm.deal(address(nftMarket), 1000 ether);
        deal(address(token), user2, 1 ether);
        deal(address(token), user, 1 ether);

        // // 用户2批准NFT市场购买NFT
        vm.prank(user2);
        token.approve(address(nftMarket), 1 ether);

        // 用户2购买NFT
        vm.prank(user2);
        nftMarket.buyNFT(orderId2);

        assertEq(nft.ownerOf(nftId), user2, "NFT should belong to user2");
        assertEq(token.balanceOf(user2), 1 ether - price, "User2 should have 999999900 tokens");
        assertEq(nftMarket.getNFTPrice(orderId2), 0, "NFT should be delisted");
    }

    //2 测试通过ETH上架和购买
    function test_list_and_buy2() public {
        IERC20 token = IERC20(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        uint256 price = 1000000;
        uint256 deadline = block.timestamp + 1 days;
        ListOrder memory order =
            ListOrder({nft: address(nft), tokenId: nftId, payToken: address(token), price: price, deadline: deadline});
        bytes32 orderId = nftMarket.orderHash(order);
        console.logBytes32(orderId);
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(orderId);
        console.logBytes32(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        address signer = ECDSA.recover(messageHash, signature);
        assertEq(signer, address(user), "Invalid signature");

        assertEq(nft.ownerOf(nftId), user, "NFT should belong to user");

        // 上架 NFT
        vm.prank(user);
        nftMarket.listNFT(order, signature);

        // 获取订单ID
        bytes32 orderId2 = nftMarket.listing(address(nft), nftId);
        assertEq(orderId2, orderId, "Order ID should match");

        // 给用户2一些Token
        vm.deal(user, 1000 ether);
        vm.deal(user2, 1000 ether);

        // fee 0.3% or 0
        uint256 fee = price * 30 / 10000;
        uint256 value1 = price + fee;

        // 用户2购买NFT
        vm.prank(user2);
        nftMarket.buyNFT{value: value1}(orderId2);

        assertEq(nft.ownerOf(nftId), user2, "NFT should belong to user2");
        assertEq(user2.balance, 1000 ether - value1, "User2 should have 999999900 tokens");
        assertEq(nftMarket.getNFTPrice(orderId2), 0, "NFT should be delisted");
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(nftMarket.buildDomainSeparator(), structHash);
    }

    function orderHash(ListOrder memory order) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("ListOrder(address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"),
                order.nft,
                order.tokenId,
                order.payToken,
                order.price,
                order.deadline
            )
        );
        // Generate the final hash that complies with EIP712
        return _hashTypedDataV4(structHash);
    }
}
