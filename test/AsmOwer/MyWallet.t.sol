// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/AsmOwer/MyWallet.sol";

contract MyWalletTest is Test {
    MyWallet myWallet;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    function setUp() public {
        myWallet = new MyWallet("MyWallet");
    }
    /*
     测试 读取 owner 地址
    */
    function test_getOwner() public {
        assertEq(myWallet.getOwner(), address(this));
    }
    /*
     测试 设置 owner 地址
    */
    function test_setOwner() public {
        myWallet.setOwner(alice);
        assertEq(myWallet.getOwner(), alice);
    }


    /*
     测试 转移 owner 地址
    */
    function test_transferOwnership() public {
        myWallet.transferOwnership(bob);
        assertEq(myWallet.getOwner(), bob);
    } 
}
