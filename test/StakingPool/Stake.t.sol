// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {StakePoolV2} from "@src/StakingPool/StakePoolV2.sol";
import {esRNT} from "@src/RNT/esRNT.sol";

contract StakeTest is Test {
    esRNT public kkToken;
    StakePoolV2 public stakeContract;
    address user = address(this);

    function setUp() public {
        // Deploy the mock token
        kkToken = new esRNT();
        // Deploy the stake contract with the mock token address
        stakeContract = new StakePoolV2(kkToken);
        // 将KK Token的ownership转移给质押合约
        kkToken.transferOwnership(address(stakeContract));
    }

    // Test staking functionality
    /*
     * 测试质押功能
     */
    function testStake() public {
        vm.deal(user, 1 ether);
        vm.prank(user); // Impersonate the user
        stakeContract.stake{value: 1 ether}();
        assertEq(user.balance, 0 ether);
    }

    // Test unstaking functionality
    /*
     * 测试赎回功能
     */
    function testUnstake() public {
        address alice = makeAddr("alice");
        vm.deal(alice, 1 ether);
        // First, stake some ETH
        vm.prank(alice);
        stakeContract.stake{value: 1 ether}();
        assertEq(kkToken.balanceOf(alice), 0 ether); // KK tokens were transferred out
        assertEq(alice.balance, 0 ether); // User balance should be restored after unstaking

        //步过10个区块
        vm.roll(block.number + 100);

        // Then, unstake it
        vm.prank(alice);
        stakeContract.unstake(1 ether);

        // Check that KK tokens were transferred and ETH was returned to the user
        assertEq(kkToken.balanceOf(alice), 100 * 10); // KK tokens were transferred out
        assertEq(alice.balance, 1 ether); // User balance should be restored after unstaking
    }

    // Test claiming functionality
    /*
     * 测试领取奖励功能
     */
    function testClaim() public {
        address alice = makeAddr("alice");
        vm.deal(alice, 1 ether);
        // First, stake some ETH
        vm.prank(alice);
        stakeContract.stake{value: 1 ether}();

        //步过10个区块
        vm.roll(block.number + 10);

        // Claim the KK token reward
        vm.prank(alice);
        stakeContract.claim();

        // Check that the user still holds the KK tokens they initially minted by staking
        assertEq(kkToken.balanceOf(alice), 100);
    }

    receive() external payable {}
}
