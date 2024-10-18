// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyFirstToken} from "../src/MyFirstToken.sol";
//使用你在 Decert.met 登录的钱包来部署合约
//0x377D734D0DAB9ee92f2649D31C3c3f48AdCa6c37
/*forge script DeployMyToken --rpc-url  https://rpc.sepolia.org \
--private-key AA \
--broadcast */

contract DeployMyToken is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyFirstToken token = new MyFirstToken("MyToken", "MTK");
        console.log("token address:", address(token));
        console.log("token name:", token.name());
        console.log("token symbol:", token.symbol());
        console.log("token decimals:", token.decimals());
        console.log("token totalSupply:", token.totalSupply());
        address admin = address(0x377D734D0DAB9ee92f2649D31C3c3f48AdCa6c37);
        token.transfer(admin, 100000000 * 10 ** 18);
        vm.stopBroadcast();
    }
}
