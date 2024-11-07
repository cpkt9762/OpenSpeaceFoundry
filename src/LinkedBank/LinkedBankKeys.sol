// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
/*
 * 链表节点
 * 这个链表是按照存款金额排序的
 */

library LinkedBankKeys {
    struct Node {
        address user;
        uint256 amount;
        address next;
    }

    struct List {
        uint256 size;
        mapping(address => Node) list;
        address head;
    }

    /*
     * 检查用户是否已存在
     */
    function Exists(List storage self, address key) public view returns (bool) {
        return self.list[key].user != address(0);
    }

    /*
     * 插入或更新存款金额，并按金额排序链表中的前 10 名用户
     */
    function Insert(List storage self, address key, uint256 amount) public {
        if (Exists(self, key)) {
            self.list[key].amount += amount;
            _reorder(self, key);
        } else {
            Node memory newNode = Node({user: key, amount: amount, next: address(0)});
            if (self.head == address(0)) {
                self.head = key;
                self.list[key] = newNode;
                self.size = 1;
            } else {
                // 如果头节点的金额小于新节点的金额，则将新节点插入到头节点之前
                if (self.list[self.head].amount < amount) {
                    newNode.next = self.head;
                    self.head = key;
                    self.list[key] = newNode;
                } else {
                    _insertSorted(self, key, newNode);
                }
                self.size++;
            }
        }
    }

    /*
     * 插入到链表中的适当位置
     */
    function _insertSorted(List storage self, address key, Node memory newNode) internal {
        address current = self.head;
        while (self.list[current].next != address(0) && self.list[self.list[current].next].amount >= newNode.amount) {
            current = self.list[current].next;
        }
        newNode.next = self.list[current].next;
        self.list[current].next = key;
        self.list[key] = newNode;
    }

    /*
     * 重新排序链表
     */
    function _reorder(List storage self, address key) internal {
        address current = self.head;
        address prev = address(0);

        // 移动 key 节点到链表中的新位置
        while (current != address(0)) {
            if (current == key) {
                if (prev != address(0)) {
                    self.list[prev].next = self.list[current].next;
                }
                if (key == self.head) {
                    self.head = self.list[key].next;
                }
                _insertSorted(self, key, self.list[key]);
                return;
            }
            prev = current;
            current = self.list[current].next;
        }
    }

    /*
     * 移除链表中的最后一个节点
     */
    function _removeLast(List storage self) internal {
        address current = self.head;
        address prev = address(0);

        while (self.list[current].next != address(0)) {
            prev = current;
            current = self.list[current].next;
        }

        if (prev != address(0)) {
            self.list[prev].next = address(0);
        } else {
            self.head = address(0);
        }
        delete self.list[current];
        self.size--;
    }

    /*
     * 获取存款信息
     */
    function Get(List storage self, address key) public view returns (Node memory) {
        return self.list[key];
    }

    /*
     * 获取下一个节点
     */
    function Next(List storage self, address key) public view returns (address) {
        return self.list[key].next;
    }

    /*
     * 获取头节点
     */
    function Head(List storage self) public view returns (address) {
        return self.head;
    }

    /*
     * 获取当前链表大小
     */
    function Size(List storage self) public view returns (uint256) {
        return self.size;
    }
}
