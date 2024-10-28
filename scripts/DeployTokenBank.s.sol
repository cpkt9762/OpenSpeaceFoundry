// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenBankV2} from "../src/TokenBank.sol"; 
import {MyPermitToken} from "../src/MyPermitToken.sol"; 
//使用你在 Decert.met 登录的钱包来部署合约 

contract DeployTokenBank is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyPermitToken myToken = new MyPermitToken();  
        TokenBankV2 tokenBank = new TokenBankV2(address(myToken));  
        vm.stopBroadcast();
    }
}
