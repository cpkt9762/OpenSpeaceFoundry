// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/UpdateNFTMarket/NFTMarketplaceV1.sol";
import "@src/UpdateNFTMarket/NFTMarketplaceV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol"; 
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@src/UpdateNFTMarket/NFTMarketplaceProxy.sol";
import "@src/MyERC721NFT.sol";
import "@src/UpdateNFTMarket/TimeLock.sol";
contract NFTMarketplaceTest is Test {
    NFTMarketplaceV1 nftMarketplaceV1;
    NFTMarketplaceV2 nftMarketplaceV2;
    NFTMarketplaceV1 proxyAsV1; 
    address proxyAddress;
    address admin;
    uint256 adminpk;
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    TimeLock timeLock;
    uint256 constant MIN_DELAY = 1 days;
    function setUp() public {
        (admin, adminpk) = makeAddrAndKey("admin");  
        nftMarketplaceV1 = new NFTMarketplaceV1();  
        // 部署代理并设置 TimeLock
        bytes memory data = abi.encodeWithSignature("initialize(address)", admin);  

        //proxy 
        vm.prank(admin);
        proxyAddress = Upgrades.deployTransparentProxy("NFTMarketplaceV1.sol",admin,data);
        console.log("proxyAddress",proxyAddress);
        
        // 获取代理地址的合约实例 (V1接口)
        proxyAsV1 = NFTMarketplaceV1(address(proxyAddress));
        console.log("proxyAsV1",address(proxyAsV1));

    } 

    /* 
    测试升级到V2
    */
    function testUpgradeToV2() public { 
 
        // 升级代理
        Upgrades.upgradeProxy(address(proxyAddress), "NFTMarketplaceV2.sol:NFTMarketplaceV2", "",admin);

        // 验证升级后的功能是否有效 (V2接口)a
        NFTMarketplaceV2 proxyAsV2 = NFTMarketplaceV2(address(proxyAddress)); 
        assertEq(proxyAsV2.version(), "2", "Version mismatch");
      
    }

    /* 
    测试V2上架NFT
    */
    function testlistNFTWithSignature() public { 
        nftMarketplaceV2 = new NFTMarketplaceV2(); 
        MyERC721NFT nft = new MyERC721NFT(); 

       
        uint256 price = 1 ether;
        uint256 deadline = block.timestamp + 1 days;
        address payToken = ETH_FLAG;
        address seller = admin;

        vm.prank(seller);
        uint256 tokenId = nft.mintNFT("www.baidu.com");

        //一次性授权
        vm.prank(seller);
        nft.setApprovalForAll(address(nftMarketplaceV2), true); 
        assertEq(nft.isApprovedForAll(address(seller),address(nftMarketplaceV2)), true, "Approval not set");
 
    
        bytes32 structHash = keccak256(abi.encode(seller, address(nft), tokenId, payToken, price));
        bytes32 _message = MessageHashUtils.toEthSignedMessageHash(structHash);

        // 签名
        ( uint8 v,bytes32 r, bytes32 s) = vm.sign(adminpk,_message);
        bytes memory signature = abi.encodePacked(r, s, bytes1(v));
      
        address signer = ECDSA.recover(_message, signature);
        assertEq(signer, admin, "Invalid signature");

        // 调用V2通过签名上架NFT接口
        vm.prank(seller);
        nftMarketplaceV2.listNFTWithSignature(address(nft), tokenId, payToken, price, deadline, signature); 


        ListOrder memory order = nftMarketplaceV2.listing(address(nft), tokenId); 
        assertEq(order.orderId,_message, "OrderId mismatch");
        // 验证NFT是否上架
        assertEq(order.price, price, "NFT not listed");


        address buyer = address(1);
        vm.deal(buyer, 1 ether);

        //测试购买
        vm.prank(buyer);
        nftMarketplaceV2.buyNFT{value: price}(order.orderId);
        assertEq(nft.ownerOf(tokenId), buyer, "NFT not bought");

    }
}
