// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/RNT/StakePool.sol";
import "../../src/RNT/RNT.sol";
import "../../src/RNT/esRNT.sol";

contract StakingTest is Test {
    StakePool stakePool;
    RNT rntToken;
    esRNT esRntToken;
    address user = makeAddr("alice");

    function setUp() public {
        rntToken = new RNT();
        esRntToken = new esRNT(rntToken); 
        stakePool = new StakePool(rntToken, esRntToken); 
        esRntToken.mint(address(stakePool), 1000000 ether);
        assertEq(esRntToken.balanceOf(address(stakePool)), 1000000 ether);
        vm.deal(user, 1000 ether); 
        esRntToken.transferOwnership(address(stakePool));
        vm.startPrank(user);       
        rntToken.approve(address(stakePool), 100 ether);  
        esRntToken.approve(address(stakePool), 100 ether);
        vm.stopPrank();
    
     
    }

    /*
    测试质押
    */
    function testStake() public {
        vm.startPrank(user);
        deal(address(rntToken), user, 1000 ether); 
        stakePool.stake(10 ether);
        StakeInfo memory stakeInfo = stakePool.getStakeInfo();
        assertEq(stakeInfo.staked, 10 ether);
        vm.stopPrank();
    }

    /*
    测试领取奖励
    */
    function testClaimReward() public { 
        vm.startPrank(user); 
        deal(address(rntToken), user, 1000000 ether);  
        stakePool.stake(10 ether);
        skip(10); 
        stakePool.claim();
        assertGt(rntToken.balanceOf(user), 0);
        vm.stopPrank();
    }

    /*
    测试解押
    */
    function testWithdraw() public { 
        vm.startPrank(user);
        deal(address(rntToken), user, 10 ether); 
        stakePool.stake(10 ether);
        stakePool.withdraw(10 ether);
        assertEq(rntToken.balanceOf(user), 10 ether);
        vm.stopPrank();
    }
    /*
    测试兑换 esRNT 为 RNT
    */
    function testRedeemEsRNT() public {
        vm.startPrank(user);
        deal(address(rntToken), user, 10 ether);  
        //质押 10 RNT
        stakePool.stake(10 ether);   
        skip(30 days);
        stakePool.redeemEsRNT();
        assertEq(rntToken.balanceOf(user), 10 ether);
        vm.stopPrank();
    }
}
