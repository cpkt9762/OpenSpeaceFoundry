// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/Erc20Token.sol";

contract TokenBankTest is Test {
    TokenBank tokenBank;
    MyERC20Token token;
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        token = new MyERC20Token(); 
        address tokenAddress = address(token);
        tokenBank = new TokenBank(tokenAddress);
        token.approve(address(tokenBank), 100);
    }
    //测试存款
    function test_deposit() public {
        tokenBank.deposit(100);
    }
}