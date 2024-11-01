import { ethers } from 'ethers';
import { createPublicClient, http } from 'viem'; 
import { sepolia } from 'viem/chains';
import TokenBankV2 from "./abi/TokenBankV2.json";
import MyPermit2 from "./abi/MyPermit2.json";
import MyPermitToken from "./abi/MyPermitToken.json"





// 合约地址
const tokenName = 'MyPermitToken';
const tokenAddress = '0x174E0276F66328c9531BC8E167D13707A038D8E0';
const permit2Address = '0x65a2Aec8b5D41E0da2ed3D312a5e10c0ea07528C';
const tokenBankAddress = '0xbe6c3eecccd8912e326fc4b444f16253e7b408bb';
 
 
//从环境变量中读取私钥
const userPrivateKey = process.env.USER_PRIVATE_KEY;
const userAddress = process.env.USER_ADDRESS;

const chainId = 11155111;
const chainName = 'sepolia';
const rpcUrl = 'https://1rpc.io/sepolia';

// 测试数据
const amount = ethers.utils.parseUnits('10', 18); // 10 ERC20 代币
const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 小时后 

// Viem 配置
const client = createPublicClient({
  chain: sepolia,
  transport: http(rpcUrl), 
});

// Define permit structures
interface TokenPermissions {
  token: string;
  amount: ethers.BigNumber;
}

interface PermitTransferFrom {
  permitted: TokenPermissions;
  nonce: ethers.BigNumber;
  deadline: ethers.BigNumber;
}

// Define constants for type hashes
const TOKEN_PERMISSIONS_TYPEHASH = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("TokenPermissions(address token,uint256 amount)")
);

const PERMIT_TRANSFER_FROM_TYPEHASH = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)")
);  
const PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)")
);
 // _getEIP712Hash 实现
// function getEIP712Hash(permit, spender, domainSeparator) {
//   // 计算 TokenPermissions 的哈希
//   const tokenPermissionsHash = ethers.utils.keccak256(
//     ethers.utils.defaultAbiCoder.encode(
//       ["bytes32", "address", "uint256"],
//       [TOKEN_PERMISSIONS_TYPEHASH, permit.permitted.token, permit.permitted.amount]
//     )
//   );

//   // 计算 PermitTransferFrom 的哈希
//   const structHash = ethers.utils.keccak256(
//     ethers.utils.defaultAbiCoder.encode(
//       ["bytes32", "bytes32", "address", "uint256", "uint256"],
//       [
//         PERMIT_TRANSFER_FROM_TYPEHASH,
//         tokenPermissionsHash,
//         spender,
//         permit.nonce,
//         permit.deadline,
//       ]
//     )
//   );

//   // 计算最终的 EIP-712 哈希
//   const eip712Hash = ethers.utils.keccak256(
//     ethers.utils.concat([
//       ethers.utils.toUtf8Bytes("\x19\x01"),
//       domainSeparator,
//       structHash
//     ])
//   );

//   return eip712Hash;
// }


function getEIP712Hash(permit:PermitTransferFrom, spender:string,domainSeparator:string) {
  //const DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR; // 假设有一个permit2对象，可以访问到DOMAIN_SEPARATOR
  const PERMIT_TRANSFER_FROM_TYPEHASH = ethers.utils.id("PermitTransferFrom(address token,uint256 amount,address spender,uint256 nonce,uint256 deadline)");
  const TOKEN_PERMISSIONS_TYPEHASH = ethers.utils.id("TokenPermissions(address token,uint256 amount)");

  const tokenPermissionsHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "uint256"],
      [TOKEN_PERMISSIONS_TYPEHASH, permit.permitted.token, permit.permitted.amount]
  ));

  const permitTransferFromHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes32", "address", "uint256", "uint256"],
      [PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, spender, permit.nonce, permit.deadline]
  ));

  const eip712Hash = ethers.utils.keccak256(ethers.utils.solidityPack(
      ["string", "bytes32", "bytes32"],
      ["\x19\x01", domainSeparator, permitTransferFromHash]
  ));

  return eip712Hash;
}

// function getEIP712Hash(permit:PermitTransferFrom, spender:string,domainSeparator:string) {
//   //const DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR; // 假设有一个permit2对象，可以访问到DOMAIN_SEPARATOR
//    const PERMIT_TRANSFER_FROM_TYPEHASH = ethers.utils.id("PermitTransferFrom(address token,uint256 amount,address spender,uint256 nonce,uint256 deadline)");
//    const TOKEN_PERMISSIONS_TYPEHASH = ethers.utils.id("TokenPermissions(address token,uint256 amount)");
  
//  const tokenPermissionsHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
//   ["bytes32", "address", "uint256"],
//   [TOKEN_PERMISSIONS_TYPEHASH, permit.permitted.token, permit.permitted.amount]
//   ));
  
//    const permitTransferFromHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
//   ["bytes32", "bytes32", "address", "uint256", "uint256"],
//    [PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, spender, permit.nonce, permit.deadline]
//    ));
  
//    const eip712Hash = ethers.utils.keccak256(ethers.utils.solidityPack(
//   ["string", "bytes32", "bytes32"],
//    ["\x19\x01", domainSeparator, permitTransferFromHash]
//  ));
//  console.log("eip712Hash:",eip712Hash);
  
//   return eip712Hash;
//   }
// // EIP712 hash generation function
// async function getEIP712Hash(
//   permit: PermitTransferFrom,
//   spender: string,
//   domainSeparator: string
// ): Promise<string> {
//   console.log("permit:",permit);
//   console.log("spender:",spender);
//   console.log("domainSeparator:",domainSeparator);
//   console.log("PERMIT_TRANSFER_FROM_TYPEHASH:",PERMIT_TRANSFER_FROM_TYPEHASH);
//   console.log("TOKEN_PERMISSIONS_TYPEHASH:",TOKEN_PERMISSIONS_TYPEHASH);
  
//   const permitHash = ethers.utils.keccak256(
//       ethers.utils.defaultAbiCoder.encode(
//           ["bytes32", "bytes32", "address", "uint256", "uint256"],
//           [
//             PERMIT_TRANSFER_FROM_TYPEHASH,
//               ethers.utils.keccak256(
//                   ethers.utils.defaultAbiCoder.encode(
//                       ["bytes32", "address", "uint256"],
//                       [
//                           TOKEN_PERMISSIONS_TYPEHASH,
//                           permit.permitted.token,
//                           permit.permitted.amount,
//                       ]
//                   )
//               ),
//               spender,
//               permit.nonce,
//               permit.deadline,
//           ]
//       )
//   );

//   return ethers.utils.keccak256(
//       ethers.utils.concat([
//           ethers.utils.toUtf8Bytes("\x19\x01"),
//           ethers.utils.arrayify(domainSeparator),
//           ethers.utils.arrayify(permitHash),
//       ])
//   );
// }

// Function to sign the hash
async function signPermit(
  privateKey: string,
  permit: PermitTransferFrom,
  spender: string,
  domainSeparator: string
) {
  // Get the EIP712 hash
  const permitHash = await getEIP712Hash(permit, spender, domainSeparator);
  console.log("permitHash:",permitHash);
  // Sign the hash with the private key
  const wallet = new ethers.Wallet(privateKey);
  const signature = await wallet.signMessage(permitHash); 
  return signature;
}


const types = {
  PermitTransferFrom: [
      { name: "permitted", type: "TokenPermissions" },
      { name: "spender", type: "address" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
  ],
  TokenPermissions: [
      { name: "token", type: "address" },
      { name: "amount", type: "uint256" },
  ],
};

const message = {
  permitted: {
      token: tokenAddress,
      amount: amount,
  },
  spender: tokenBankAddress,
  nonce: 111,
  deadline: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
};

async function signAndSplitEIP712(wallet:ethers.Wallet,domain:any) {
  // Sign the message using EIP-712
  const signature = await wallet._signTypedData(domain, types, message);

  // Split the signature into r, s, and v
  const { v, r, s } = ethers.utils.splitSignature(signature);

  console.log("Signature:", signature);
  console.log("v:", v);
  console.log("r:", r);
  console.log("s:", s);

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

  const permit2Contract = new ethers.Contract(permit2Address, MyPermit2.abi, wallet);

  //1. 设置合约实例
  const tokenContract = new ethers.Contract(tokenAddress, MyPermitToken.abi, wallet);
  const tokenBankContract = new ethers.Contract(tokenBankAddress, TokenBankV2.abi, wallet); 

 
 let nonce =255;  //await tokenContract.nonces(userAddress);
 console.log("nonce:",nonce);
 let deadline = Math.floor(Date.now() / 1000) + 3600; // 1 小时后 
  // Usage example 
  const permit: PermitTransferFrom = {
      permitted: {
          token: tokenAddress, // Replace with your token address
          amount: amount // Replace with the amount
      },
      nonce: ethers.BigNumber.from(nonce), // Replace with the nonce
      deadline: ethers.BigNumber.from(deadline) // Replace with your deadline
  };

  const spender = tokenBankAddress; // Replace with your token bank address
   const domainSeparator = "0x02c08a83cd5947dc1019eda06d63b5d9388f8a4c7510733bc0ef4aee2fbd4ef1";//await permit2Contract.DOMAIN_SEPARATOR(); // Replace with your domain separator
   console.log("domainSeparator:",domainSeparator);
  // Define EIP-712 Domain, Types, and Message (same as before)
  const domain = {
    name: "MyPermit2",
    version: "1",
    chainId: 1, // Mainnet or respective chain ID
    verifyingContract: domainSeparator,
  };
  const { v, r, s } = await  signAndSplitEIP712(wallet,domain);
  console.log("signature:",{ v, r, s });
  //3. 用户先批准 TokenBank 合约
  const approveTx = await tokenContract.approve(tokenBankAddress, amount);
  await approveTx.wait();  
  const approveTx2 = await tokenContract.approve(permit2Address,amount);
  await approveTx2.wait();

  console.log('Approval transaction successful.');
   

//   // try {
//   //   const estimatedGas = await tokenBankContract.estimateGas.depositWithPermit2(
//   //     tokenAddress,
//   //       amount,
//   //       deadline,
//   //       nonce,
//   //       v,
//   //       r,
//   //       s
//   //   );
//   //   console.log("Estimated Gas:", estimatedGas.toString());

//   //   const tx = await tokenBankContract.depositWithPermit2(
//   //     tokenAddress,
//   //       amount,
//   //       deadline,
//   //       nonce,
//   //       v,
//   //       r,
//   //       s,
//   //       { gasLimit: estimatedGas.add(10000) } // Slightly increase estimated gas
//   //   );
//   //   console.log("Transaction hash:", tx.hash);
// } catch (error) {
//     console.error("Error estimating or sending transaction:", error);
// }


  // // 4. 用户调用 depositWithPermit2 方法 
  // const tx = await tokenBankContract.depositWithPermit2(tokenAddress,amount, deadline,nonce, v, r, s,{
  //   gasLimit: ethers.utils.hexlify(500000), // Specify a gas limit (adjust as needed)
  //   gasPrice: ethers.utils.parseUnits("20", "gwei"), // Set custom gas price if necessary
  // });
  // console.log("Transaction hash:", tx.hash);
  // await tx.wait(); 

  // console.log('DepositWithPermit2 transaction successful.');

  // // 5. 检查余额
  // const balance = await tokenBankContract.balances(userAddress);
  // console.log('User balance in TokenBank:', ethers.utils.formatUnits(balance, 18));
}

// testDepositWithPermit2().catch((error) => {
//   console.error('Error testing depositWithPermit2:', error);
// });



// Helper function to encode TokenPermissions array
function encodeTokenPermissions(permissions: { token: string; amount: string }[]): string {
    return ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
            ["bytes32[]"],
            [
                permissions.map((permission) =>
                    ethers.utils.keccak256(
                        ethers.utils.defaultAbiCoder.encode(
                            ["bytes32", "address", "uint256"],
                            [TOKEN_PERMISSIONS_TYPEHASH, permission.token, permission.amount]
                        )
                    )
                ),
            ]
        )
    );
}

// Main function to get the signature
async function getPermitBatchTransferSignature(
    permit: {
        permitted: { token: string; amount: string }[];
        nonce: string;
        deadline: string;
    },
    privateKey: string,
    domainSeparator: string,
    spender: string
): Promise<string> {
    const tokenPermissionsHash = encodeTokenPermissions(permit.permitted);

    // Compute the msgHash
    const msgHash = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
            ["bytes32", "bytes32", "address", "uint256", "uint256"],
            [
                PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                tokenPermissionsHash,
                spender,
                permit.nonce,
                permit.deadline,
            ]
        )
    );

    const finalHash = ethers.utils.keccak256(
        ethers.utils.solidityPack(["string", "bytes32", "bytes32"], ["\x19\x01", domainSeparator, msgHash])
    );

    // Sign the finalHash with private key
    const wallet = new ethers.Wallet(privateKey);
    const signature = await wallet.signMessage(ethers.utils.arrayify(finalHash));
    return signature;

    // // Split signature into r, s, and v
    // const { v, r, s } = ethers.utils.splitSignature(signature);

    // // Concatenate r, s, and v as per Solidity's return
    // return ethers.utils.hexConcat([ ethers.utils.hexlify(v),r, s]);
}

// Example usage
(async () => {
    const privateKey = userPrivateKey;
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);
    const permit2Contract = new ethers.Contract(permit2Address, MyPermit2.abi, wallet);
    const tokenContract = new ethers.Contract(tokenAddress, MyPermitToken.abi, wallet);
    const tokenBankContract = new ethers.Contract(tokenBankAddress, TokenBankV2.abi, wallet);
    const domainSeparator = await permit2Contract.DOMAIN_SEPARATOR();
    const spender = tokenBankAddress;
    console.log("domainSeparator:",domainSeparator);

    console.log('Approval transaction successful.'); 
    let nonce =100;  //await tokenContract.nonces(userAddress);
    console.log("nonce:",nonce);
    const amount =100; // 10 ERC20 代币
    let deadline =1000;// Math.floor(Date.now() / 1000) + 3600; // 1 小时后 
     // Usage example 
     const permit: PermitTransferFrom = {
         permitted: {
             token: tokenAddress, // Replace with your token address
             amount: ethers.BigNumber.from(amount) // Replace with the amount
         },
         nonce: ethers.BigNumber.from(nonce), // Replace with the nonce
         deadline: ethers.BigNumber.from(deadline) // Replace with your deadline
     };
     /*  signer 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
  0xb9f6e892e513164b3f8ea7a0c88e14cbdffab36392236b368b7f1d64a3e1d1224f7291e013730e3cb72c6b59be6fc2e5e884f79638c603ff4b4b919ede342d841b
    signer 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
    //0x598da6a3465ab1109cd41bf3e20c20deea6fdeab7a6a6a4c457a059a81a7306b
    //0x8072ea506576bfcd72878e9fa2335d5e958c58d17cc73ddfa07a41d83c67e7f6
  0xf73ab45cd7b842878f0ffd09054b8813f186275c10a3296ef1d997615909ace2474be79666e5f9da7e73822a4b489a3c404068dc2ff077467c3433bd7406316e1b
*/
     const signature = await  signPermit(privateKey,permit,spender,domainSeparator);
     console.log("signature:",signature); // Use console.logBytes for logging bytes
      // Split signature into r, s, and v 
   
      const tx = await tokenBankContract.depositWithPermit2(
        tokenAddress,
          amount,
          deadline,
          nonce,
          signature,
          {  
            gasLimit: ethers.utils.hexlify(500000), // Specify a gas limit (adjust as needed)
            gasPrice: ethers.utils.parseUnits("20", "gwei"), // Set custom gas price if necessary } // Slightly increase estimated gas  
          }
      );
      console.log("Estimated Gas:", tx.toString());
      await tx.wait();

})();