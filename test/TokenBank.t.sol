// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/MyPermitToken.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract TokenBankTest is Test {
    TokenBankV2 tokenBank;
    MyPermitToken myToken;
    MyPermit2 permit2;
    address public user;
    uint256 privateKey;
    event Deposit(address indexed user, uint256 amount);
    bytes32 constant TOKEN_PERMISSIONS_TYPEHASH =
        keccak256("TokenPermissions(address token,uint256 amount)");
    bytes32 constant PERMIT_TRANSFER_FROM_TYPEHASH = 
        keccak256("PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)");
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_sepolia"); 
        privateKey = uint256(keccak256(abi.encodePacked("user")));
        user = vm.addr(privateKey);

        vm.startPrank(user);
        myToken = new MyPermitToken();
        address tokenAddress = address(myToken);
        permit2 = new MyPermit2();
        tokenBank = new TokenBankV2(IPermit2(address(permit2)));  
        myToken.mint(user, 100000); 
        vm.stopPrank();
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

 
    function test_DepositWithPermit2() public {
        // User signs a permit allowing TokenBank to spend on their behalf
        uint256 nonce =  myToken.nonces(user);
        uint256 deadline = block.timestamp + 1 days;
        uint256 amount = 100; // 100 tokens  
        address tokenAddress = address(0x174E0276F66328c9531BC8E167D13707A038D8E0);
        deal(address(tokenAddress), user, amount*1e18);
        // Structs for permit signature
        IPermit2.TokenPermissions memory permissions = ISignatureTransfer.TokenPermissions({
            token: address(tokenAddress),
            amount: amount
        });

        IPermit2.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: permissions,
            nonce: nonce,
            deadline: deadline
        });
        bytes32 permitHash = _getEIP712Hash(permit, address(tokenBank)); 
        console.log("permitHash");
        console.logBytes32(permitHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, permitHash);
        address signer=ecrecover(permitHash,v, r, s);
        console.log("signer",signer);
        assertEq(signer,user);

        bytes memory signature =abi.encodePacked(r, s, v);
        console.logBytes(signature); // Use console.logBytes for logging bytes
        // User calls depositWithPermit2
        vm.startPrank(user); 
        myToken.approve(address(tokenBank), amount*1e18); 
        myToken.approve(address(permit2), amount*1e18);
        tokenBank.depositWithPermit2(IERC20(myToken), amount, deadline, nonce,  signature);
        
        vm.stopPrank();
       

        // Verify deposit: Check tokenBank's balance increased by `amount`
        assertEq(myToken.balanceOf(address(tokenBank)), amount, "Deposit failed"); 
    } 
    function _getEIP712Hash(IPermit2.PermitTransferFrom memory permit, address spender)
        internal
        view
        returns (bytes32 hash)
    {
        console.log("permit");
        console.logBytes(abi.encode(permit));
        console.log("spender",spender);
        console.log("domainSeparator");
        console.logBytes(abi.encode(permit2.DOMAIN_SEPARATOR()));
        console.log("PERMIT_TRANSFER_FROM_TYPEHASH");
        console.logBytes32(PERMIT_TRANSFER_FROM_TYPEHASH);
        console.log("TOKEN_PERMISSIONS_TYPEHASH");
        console.logBytes(abi.encode(TOKEN_PERMISSIONS_TYPEHASH));
        return keccak256(abi.encodePacked(
            "\x19\x01",
            permit2.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                PERMIT_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encode(
                    TOKEN_PERMISSIONS_TYPEHASH,
                    permit.permitted.token,
                    permit.permitted.amount
                )),
                spender,
                permit.nonce,
                permit.deadline
            ))
        ));
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
                myToken.DOMAIN_SEPARATOR(),
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
