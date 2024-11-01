// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenBankV2} from "../src/TokenBank.sol"; 
import {MyPermitToken,MyPermit2} from "../src/MyPermitToken.sol"; 
import {IPermit2} from "lib/permit2/src/interfaces/IPermit2.sol";
//使用你在 Decert.met 登录的钱包来部署合约 

contract DeployTokenBank is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyPermitToken myToken = new MyPermitToken();  
        MyPermit2 permit2 = new MyPermit2();
        TokenBankV2 tokenBank = new TokenBankV2(IPermit2(address(permit2)));  
        vm.stopBroadcast();
    }
}
