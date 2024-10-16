// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenHook.sol";
import "../src/TokenBank.sol";
import "../src/Erc20Token.sol";

contract TokenHookTest is Test {
    ERC20WithCallback token;
    TokenBankV2 tokenBank;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        token = new ERC20WithCallback();
        tokenBank = new TokenBankV2(address(token));
        token.approve(address(tokenBank), 1000);
    }

    //测试转账 transferWithCallback
    function test_transfer() public {
        bool success = token.transferWithCallback(address(tokenBank), 100);
        assertTrue(success);
        assertEq(token.balanceOf(address(tokenBank)), 100);
    }
}
