// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/Erc20Token.sol";

contract TokenBankTest is Test {
    TokenBank tokenBank;
    MyERC20Token token;

    event Deposit(address indexed user, uint256 amount);

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
        assertEq(token.balanceOf(address(tokenBank)), 100);
    }

    //测试depositETH
    function test_depositETH() public {
        uint256 depositAmount = 1 ether;
        //监听Deposit事件
        vm.expectEmit(address(tokenBank));
        emit Deposit(address(this), depositAmount);

        assertEq(tokenBank.getBalance(address(this)), 0);

        //记录存款前的余额
        uint256 preBalance = tokenBank.getBalance(address(this));
        tokenBank.depositETH{value: depositAmount}();

        //记录存款后的余额
        uint256 postBalance = tokenBank.getBalance(address(this));
        assertEq(postBalance - preBalance, depositAmount);
    }
}
