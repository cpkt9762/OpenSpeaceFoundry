// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/MyPermitToken.sol";

contract TokenBankTest is Test {
    TokenBankV2 tokenBank;
    MyPermitToken token;
    address public user;
    uint256 privateKey;
    event Deposit(address indexed user, uint256 amount);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia");
        token = new MyPermitToken();
        address tokenAddress = address(token);
        tokenBank = new TokenBankV2(tokenAddress);
        token.approve(address(tokenBank), 100);
        //privateKey是user的私钥
        privateKey = uint256(keccak256(abi.encodePacked("user")));
        user = vm.addr(privateKey);
    }
    //测试存款

    // function test_deposit() public {
    //     tokenBank.deposit(100);
    //     assertEq(token.balanceOf(address(tokenBank)), 100);
    // }

    // //测试depositETH
    // function test_depositETH() public {
    //     uint256 depositAmount = 1 ether;
    //     //监听Deposit事件
    //     vm.expectEmit(address(tokenBank));
    //     emit Deposit(address(this), depositAmount);

    //     assertEq(tokenBank.getBalance(address(this)), 0);

    //     //记录存款前的余额
    //     uint256 preBalance = tokenBank.getBalance(address(this));
    //     tokenBank.depositETH{value: depositAmount}();

    //     //记录存款后的余额
    //     uint256 postBalance = tokenBank.getBalance(address(this));
    //     assertEq(postBalance - preBalance, depositAmount);
    // }
     function testDepositWithPermit2() public {
        // 设置测试数据
        uint256 amount = 10 ether;
        uint256 deadline = block.timestamp + 1 days;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce = token.nonces(user); 
        // 准备签名数据
        (v, r, s) = _getPermitSignature(user, privateKey, address(tokenBank), amount, deadline, nonce);

        // 用户授权 TokenBank 合约可以转账代币
        vm.prank(user);
        token.approve(address(tokenBank), amount);


        deal(address(token), user, amount);
        // 调用 depositWithPermit2
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, deadline, v, r, s);

        // 验证存款是否成功
        assertEq(tokenBank.balances(user), amount);
        assertEq(token.balanceOf(address(tokenBank)), amount);
    }

      function _getPermitSignature(
        address  ow,
        uint256 ow_private_key,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 nonce
    ) internal returns (uint8 v, bytes32 r, bytes32 s) { 
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(
                    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                    ow,
                    spender,
                    value,
                    nonce,
                    deadline
                ))
            )
        ); 
        (v, r, s) = vm.sign(ow_private_key, digest);
       
        return (v, r, s);
    }
}
