// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/LinkedBank/TokenBank.sol";
import "@src/LinkedBank/LinkedBankKeys.sol";

contract TokenBankTest is Test {
    TokenBank public bank;

    function setUp() public {
        bank = new TokenBank();
    }

    /*
     * 测试通过 `receive()` 向合约发送 ETH
     */
    function testReceiveDeposit() public {
        address depositor = address(1);
        uint256 depositAmount = 1 ether;

        // 向合约地址发送 ETH，触发 `receive()` 函数
        vm.deal(depositor, 10 ether); // 给测试账户充值 ETH
        vm.prank(depositor); // 模拟为 `depositor` 的账户操作
        (bool success,) = address(bank).call{value: depositAmount}("");
        assertTrue(success, "Deposit failed");

        // 检查存款记录
        uint256 depositBalance = bank.getDeposit(depositor);
        assertEq(depositBalance, depositAmount, "Deposit amount is incorrect");

        // 检查前 1 名存款者
        LinkedBankKeys.Node[] memory topDepositors = bank.getTopDepositors();
        assertEq(topDepositors[0].user, depositor, "Top depositor address is incorrect");
        assertEq(topDepositors[0].amount, depositAmount, "Top depositor amount is incorrect");
    }

    /*
     * 测试多用户存款，并确认链表排序
     */
    function testMultipleDeposits() public {
        //初始化20个用户
        address[] memory depositors = new address[](20);
        uint256[] memory depositAmounts = new uint256[](20);
        for (uint256 i = 0; i < depositors.length; i++) {
            depositors[i] = makeAddr(string.concat("depositor", vm.toString(i)));
            depositAmounts[i] = 1 ether + i;
        }

        // 给账户充值 ETH
        for (uint256 i = 0; i < depositors.length; i++) {
            vm.deal(depositors[i], 10 ether);
            vm.prank(depositors[i]);
            (bool success,) = address(bank).call{value: depositAmounts[i]}("");
            assertTrue(success, "Deposit failed");
        }

        // 检查前 10 名存款用户
        LinkedBankKeys.Node[] memory topDepositors = bank.getTopDepositors();
        for (uint256 i = 0; i < 10; i++) {
            if (i < 9) {
                assertGt(topDepositors[i].amount, topDepositors[i + 1].amount, "Top depositor amount is incorrect");
            }
        }
    }
}
