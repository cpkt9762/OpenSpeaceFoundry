// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/IDO/IDO.sol";
import "../../../src/IDO/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IDOTest is Test {
    IDO ido;
    MockERC20 token;
    address alice;

    function setUp() public {
        token = new MockERC20("Test Token", "TTK");
        ido = new IDO(IERC20(address(token)), 1 ether, 10 ether, 20 ether, 30 days);
        alice = makeAddr("alice");
        token.approve(address(ido), type(uint256).max);
        vm.deal(alice, 10 ether);
        deal(address(token), address(ido), 20 ether);
    }

    receive() external payable {}
    /*
    测试结束
    */

    function testFinalize() public {
        ido.finalize();
        assertEq(ido.finalized(), true);
    }

    /*
    贡献
    */
    function testContribution() public {
        vm.startPrank(alice);
        ido.contribute{value: 1 ether}();
        assertEq(ido.contributions(alice), 1 ether);
        vm.stopPrank();
    }

    /*
    领取代币
    */
    function testClaimTokens() public {
        vm.startPrank(alice);
        ido.contribute{value: 10 ether}();
        assertEq(address(ido).balance, 10 ether);
        vm.stopPrank();
        ido.finalize();
        vm.warp(block.timestamp + 300 days);
        vm.startPrank(alice);
        ido.claimTokens();
        assertEq(token.balanceOf(alice), 10 ether);
        vm.stopPrank();
    }

    /*
    退款
    */
    function testRefund() public {
        vm.startPrank(alice);
        vm.deal(alice, 5 ether);
        ido.contribute{value: 5 ether}();
        vm.stopPrank();
        ido.finalize();
        vm.warp(block.timestamp + 300 days);
        vm.startPrank(alice);
        ido.withdraw();
        assertEq(address(alice).balance, 5 ether);
        vm.stopPrank();
    }

    /*
    测试项目方提现
    */
    function testOwnerWithdraw() public {
        vm.startPrank(address(this));
        //修改募集到的余额
        vm.deal(address(ido), 30 ether);
        skip(3000 days);
        ido.finalize();
        vm.deal(address(this), 0 ether);
        ido.withdrawETH();
        assertEq(address(this).balance, 30 ether);
        vm.stopPrank();
    }
}
