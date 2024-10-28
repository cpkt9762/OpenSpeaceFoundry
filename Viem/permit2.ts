import { ethers } from 'ethers';
import { createPublicClient, http } from 'viem'; 
import { sepolia } from 'viem/chains';
import TokenBankV2 from "./abi/TokenBankV2.json";
import MyPermitToken from "./abi/MyPermitToken.json"




// 合约地址
const tokenName = 'MyPermitToken';
const tokenAddress = '0xabeC245F868B0Ae6d2415f2301579b8634fA7d0B';
const tokenBankAddress = '0x075b7844E813b28aA757EE37601458012029D67E';
 
// 私钥和用户地址配置
const userPrivateKey = 'userPrivateKey';
const userAddress = '0x377D734D0DAB9ee92f2649D31C3c3f48AdCa6c37';

const chainId = 11155111;
const chainName = 'sepolia';
const rpcUrl = 'https://rpc.sepolia.org';

// 测试数据
const amount = ethers.utils.parseUnits('10', 18); // 10 ERC20 代币
const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 小时后 

// Viem 配置
const client = createPublicClient({
  chain: sepolia,
  transport: http(rpcUrl), 
});

/**
 * 生成 EIP-2612 兼容的离线签名
 * @param wallet 签名者的钱包实例
 * @param tokenAddress 要授权的 ERC20 代币合约地址
 * @param spender 授权的 spender 地址
 * @param value 授权的代币数量
 * @param deadline 签名的截止时间（时间戳）
 * @returns 包含 v, r, s 的签名对象
 */
export async function generatePermitSignature(
  wallet: ethers.Wallet,
  tokenAddress: string,
  spender: string,
  value: ethers.BigNumber,
  deadline: number
) { 
  // EIP-712 域分隔符信息
  const domain = {
    name: tokenName, // ERC20 Token 名称（与合约中定义的一致）
    version: '1', // 版本号
    chainId: chainId, // 当前链 ID
    verifyingContract: tokenAddress, // 代币合约地址
  };

  // EIP-712 类型信息
  const types = {
    Permit: [
      { name: 'owner', type: 'address' }, // 签名者地址
      { name: 'spender', type: 'address' }, // 授权的 spender 地址
      { name: 'value', type: 'uint256' }, // 授权的代币数量
      { name: 'nonce', type: 'uint256' }, // 合约中的 nonce 值
      { name: 'deadline', type: 'uint256' }, // 签名有效的截止时间
    ],
  }; 
  // 获取代币合约实例
  const tokenContract = new ethers.Contract(tokenAddress, MyPermitToken.abi, wallet); 
  // 查询当前 nonce 值
  const nonce = await tokenContract.nonces(wallet.address); 
  // EIP-712 签名的消息数据
  const message = {
    owner: wallet.address,
    spender,
    value,
    nonce,
    deadline,
  }; 
  // 生成 EIP-2612 签名
  const signature = await wallet._signTypedData(domain, types, message);
  const { v, r, s } = ethers.utils.splitSignature(signature); 
  return { v, r, s };
}

async function testDepositWithPermit2() {
   
  // 设置 provider 和 signer
  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  provider.detectNetwork = async () => ({
    name: chainName,
    chainId: chainId,  
  });
  
  const wallet = new ethers.Wallet(userPrivateKey, provider); 

  //1. 设置合约实例
  const tokenContract = new ethers.Contract(tokenAddress, MyPermitToken.abi, wallet);
  const tokenBankContract = new ethers.Contract(tokenBankAddress, TokenBankV2.abi, wallet);

  //2. 获取 Permit2 签名
  const { v, r, s } = await generatePermitSignature(
    wallet,
    tokenAddress,
    tokenBankAddress,
    amount,
    deadline
  );

  //3. 用户先批准 TokenBank 合约
  const approveTx = await tokenContract.approve(tokenBankAddress, amount);
  await approveTx.wait();

  console.log('Approval transaction successful.');
   
  // 4. 用户调用 depositWithPermit2 方法
  const tx = await tokenBankContract.depositWithPermit2(amount, deadline, v, r, s);
  console.log("Transaction hash:", tx.hash);
  await tx.wait(); 

  console.log('DepositWithPermit2 transaction successful.');

  // 5. 检查余额
  const balance = await tokenBankContract.balances(userAddress);
  console.log('User balance in TokenBank:', ethers.utils.formatUnits(balance, 18));
}

testDepositWithPermit2().catch((error) => {
  console.error('Error testing depositWithPermit2:', error);
});
