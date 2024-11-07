// script/DeployNFTMarketplace.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {NFTMarketplaceV1} from "../src/UpdateNFTMarket/NFTMarketplaceV1.sol";
import {NFTMarketplaceV2} from "../src/UpdateNFTMarket/NFTMarketplaceV2.sol";
import {NFTMarketplaceProxy} from "../src/UpdateNFTMarket/NFTMarketplaceProxy.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployNFTMarketplace is Script {
    address public admin;
    uint256 public constant MIN_DELAY = 1 days; // TimeLock 延迟 1 天

    function run() external { 
        admin = msg.sender;
        console.log("Admin address:", admin); 
        vm.startBroadcast(); 
        NFTMarketplaceV1 nftMarketplaceV1 = new NFTMarketplaceV1();
        console.log("NFTMarketplaceV1 deployed at:", address(nftMarketplaceV1));
        
       
        bytes memory data = abi.encodeWithSignature("initialize(address)", admin);
        console.log("data");
        console.logBytes(data);

        // 部署代理
        address proxyAddress = Upgrades.deployTransparentProxy("NFTMarketplaceV1.sol",admin,data);
        console.log("proxyAddress",proxyAddress); 

        // 升级代理
        Upgrades.upgradeProxy(address(proxyAddress), "NFTMarketplaceV2.sol:NFTMarketplaceV2", "",admin); 
      

        // 获取代理地址的合约实例 (V2接口)
        NFTMarketplaceV2 proxyAsV2 = NFTMarketplaceV2(address(proxyAddress));  
        console.log("Proxy upgraded to V2 at:", address(proxyAsV2));
        vm.stopBroadcast();
    }
}
