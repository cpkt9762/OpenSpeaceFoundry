pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

 
/*要求测试内容：
1 创建多签钱包时，确定所有的多签持有⼈和签名门槛
2 多签持有⼈可提交提案
3 其他多签⼈确认提案（使⽤交易的⽅式确认即可）
4 达到多签⻔槛、任何⼈都可以执⾏交易*/

contract MultiSigWalletTest is Test {
    SimpleMultiSigWallet multiSigWallet;
    address[] owners;
    uint256 threshold;
    address user;

    function setUp() public {
            owners = [address(0x7D85Cf6DD28C89095e540E31e3bF90e965073eA6), address(0x7D85cf6dd28c89095e540E31e3Bf90e965073ea5),address(0x377D734D0DAB9ee92f2649D31C3c3f48AdCa6c37)];
            threshold = 2; 
        multiSigWallet = new SimpleMultiSigWallet(owners, threshold);
    }

    //测试提案提交
    function testSubmitProposal() public {
        vm.startPrank(owners[0]);
        
        //提交提案
        multiSigWallet.submitProposal(owners[0], 100, "test");
    }
    //测试提案确认
    function testConfirmProposal() public {
        vm.startPrank(owners[0]); 
        multiSigWallet.submitProposal(owners[0], 100, "test"); 
    } 
    //达到多签⻔槛、任何⼈都可以执⾏交易
    function testExecuteProposal() public {
            // 为合约提供 1000 wei 的余额
    vm.deal(owners[0], 1000 ether); 
    vm.deal(owners[1], 1000 ether); 
    vm.deal(owners[2], 1000 ether); 
  

    vm.deal(address(multiSigWallet), 1000 ether); // 为合约提供 1000 wei 的余额

    // 假设 owners[0], owners[1], owners[2] 是多签钱包的所有者
    vm.startPrank(owners[0]);
    
    uint proposalId=0;
    // 提交一个提案
    proposalId= multiSigWallet.submitProposal(owners[0], 100, "test");
    vm.stopPrank();
    
    // owners[1]确认提案
    vm.startPrank(owners[1]);
    multiSigWallet.confirmProposal(proposalId);
    vm.stopPrank();
    
    // owners[2]确认提案
    vm.startPrank(owners[2]);
    multiSigWallet.confirmProposal(proposalId);
    vm.stopPrank();


    console.log("address(multiSigWallet) ", address(multiSigWallet) );


    // 达到多签门槛，现在任何人都可以执行交易
    multiSigWallet.executeProposal(proposalId);
    
    // 验证提案是否成功执行
    bool executed = multiSigWallet.isExecuted(proposalId);
    assertTrue(executed, "The proposal should be executed successfully");
    }

 

}
