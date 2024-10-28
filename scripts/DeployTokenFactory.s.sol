// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol"; 
import {TokenFactoryV1} from "../src/TokenFactory.sol";
import {TokenFactoryV2} from "../src/TokenFactory.sol";
//使用你在 Decert.met 登录的钱包来部署合约 

contract DeployTokenFactory is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast(); 
        TokenFactoryV1 tokenFactory = new TokenFactoryV1(); 
        TokenFactoryV2 tokenFactoryV2 = new TokenFactoryV2(); 
        vm.stopBroadcast();
    }
}
