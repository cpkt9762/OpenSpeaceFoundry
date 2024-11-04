// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NftMarket} from "../src/NftMarket.sol";
import {MyERC721NFT} from "../src/MyERC721NFT.sol";
import {MyPermitToken} from "../src/MyPermitToken.sol";

contract DeployNftFactory is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();  
        address feeCollector = address(0xb9e2a6DC030ef79294B87f7302597F92e6d4C958);
        NftMarket nftMarketFactory = new NftMarket(feeCollector); 
        vm.stopBroadcast();
    }
}
