// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "./LinkedBankKeys.sol";
/*
 *   编写一个 Bank 存款合约，实现功能：
 *   1.可以通过 Metamask 等钱包直接给 Bank 合约地址存款
 *   2.在 Bank 合约里记录了每个地址的存款金额
 *   3.用可迭代的链表保存存款金额的前 10 名用户
 */

contract TokenBank {
    using LinkedBankKeys for LinkedBankKeys.List;

    LinkedBankKeys.List private deposits;
    mapping(address => uint256) public userDeposits;

    /*
     * 当用户直接向合约地址发送ETH时，会调用此方法
     */
    receive() external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        deposits.Insert(msg.sender, msg.value);
    }

    /*
     * 获取用户的存款余额
     */
    function getDeposit(address user) external view returns (uint256) {
        return deposits.Get(user).amount;
    }

    /*
     * 获取前 10 名存款用户
     */
    function getTopDepositors() external view returns (LinkedBankKeys.Node[] memory topDepositors) {
        topDepositors = new LinkedBankKeys.Node[](10);
        address current = deposits.Head();
        for (uint256 i = 0; i < 10; i++) {
            topDepositors[i] = deposits.Get(current);
            current = deposits.Next(current);
        }
        return topDepositors;
    }
}
