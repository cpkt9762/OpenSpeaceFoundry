
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenFactory.sol"; 
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract TokenFactoryTest is Test {
    TokenFactoryV1 tokenFactoryV1;
    TokenFactoryV2 tokenFactoryV2;
    address tokenV1Addr;
    address tokenV2Addr;
    ERC1967Proxy public proxy;
    address public owner = address(1); // Mock owner address
    function setUp() public {
       // Deploy the initial implementation of FactoryV1
        tokenFactoryV1 = new TokenFactoryV1();

        // Deploy the proxy, pointing to FactoryV1's address
        proxy = new ERC1967Proxy(address(tokenFactoryV1), "");

        // Cast the proxy address as FactoryV1
        tokenFactoryV1 = TokenFactoryV1(address(proxy));
        tokenFactoryV1.initialize(owner); // Initialize the contract with owner

        // Verify initial state
        assertEq(tokenFactoryV1.owner(), owner);
    }
    //测试升级
    function test_UpgradeToV2() public {
        // Deploy the new implementation of FactoryV2
        tokenFactoryV2 = new TokenFactoryV2();

        // Upgrade the proxy to use FactoryV2 implementation
        vm.prank(owner); // Act as the owner
        tokenFactoryV1.upgradeTo(address(tokenFactoryV2));

        // Cast the proxy address as FactoryV2
        tokenFactoryV2 = TokenFactoryV2(address(tokenFactoryV1));

        // Verify the state is consistent after the upgrade
        assertEq(tokenFactoryV2.owner(), owner);
    } 
    //测试部署和铭文
    function test_DeployAndMint() public {
        // Deploy and mint before upgrade
        string memory symbol = "TEST";
        uint totalSupply = 10000;
        uint perMint = 100;
        vm.deal(owner, 1000 ether);


        vm.prank(owner); // Act as the owner
        address tokenAddress = tokenFactoryV1.deployInscription(symbol, totalSupply, perMint);
        ERC20 token = ERC20(tokenAddress);  

        // Mint some tokens 
        vm.prank(owner);
        tokenFactoryV1.mintInscription(tokenAddress); 
        assertEq(token.balanceOf(address(owner)), perMint);

        // Upgrade to FactoryV2
        tokenFactoryV2 = new TokenFactoryV2();

        
        vm.prank(owner);
        tokenFactoryV1.upgradeTo(address(tokenFactoryV2));
        tokenFactoryV2 = TokenFactoryV2(address(proxy));
 
        // Mint again after the upgrade 
        vm.prank(owner);
        tokenFactoryV2.mintInscription(tokenAddress);
        assertEq(token.balanceOf(address(owner)), perMint*2); 
    }
}

