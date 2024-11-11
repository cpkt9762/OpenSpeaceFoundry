/*
*先实现一个 Bank 合约，
*用户可以通过 deposit() 存款， 
*然后使用 ChainLink Automation 、Gelato 或 OpenZepplin Defender Action 实现一个自动化任务，
*自动化任务实现：
*当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。
 */

* 部署 Bank 合约并开源  
  https://sepolia.etherscan.io/address/0x999c66cf7d11a88db6e74971074f652752b6b9fa#writeContract
  
* 在 ChainLink Automation 上创建任务
  https://automation.chain.link/sepolia/113156844523784035333929838266429144687826934152137156442045098032920366452750


* 部署脚本
  scripts/DeployAutoDeposit.s.sol

* 测试脚本
  test/AutoDeposit/TokenBank.t.sol
 