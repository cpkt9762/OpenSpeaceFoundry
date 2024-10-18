// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyFirstToken} from "../src/MyFirstToken.sol";
//使用你在 Decert.met 登录的钱包来部署合约 

contract DeployMyToken is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyFirstToken token = new MyFirstToken("MyToken", "MTK");  
        vm.stopBroadcast();
    }
}
