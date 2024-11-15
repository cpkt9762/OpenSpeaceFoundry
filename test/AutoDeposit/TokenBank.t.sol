// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "@src/AutoDeposit/TokenBank.sol";

contract TokenBankTest is Test {
    Bank public tokenBank;

    function setUp() public {
        tokenBank = new Bank(1 ether);
    }

    //测试当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。
    function test_automation() public {
        vm.deal(address(this), 2 ether);
        tokenBank.setThreshold(1 ether);
        tokenBank.deposit{value: 2 ether}();
        tokenBank.performUpkeep("");
        assertEq(address(tokenBank).balance, 1 ether);
        assertEq(address(tokenBank.owner()).balance, 1 ether);
    }

    receive() external payable {}
}
