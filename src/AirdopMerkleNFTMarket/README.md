 
实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：

基于 Merkel 树验证某用户是否在白名单中
在白名单中的用户可以使用上架（和之前的上架逻辑一致）指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。
要求使用 multicall( delegateCall 方式) 一次性调用两个方法：

permitPrePay() : 调用token的 permit 进行授权
claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 。
请贴出你的代码 github ，代码需包含合约，multicall 调用封装，Merkel 树的构建以及测试用例。

```bash
forge clean&&forge test -vvvvv  --match-path test/AirdopMerkleNFTMarket/AirdopMerkleNFTMarket.t.sol --ffi
```

Merkel 树的构建
```bash
 test/AirdropMerkleNFTMarke/testmerklet.js 
  /**
      * // 白名单用户地址
      *         const whitelist = [
      *         '0x1111111111111111111111111111111111111111',
      *         '0x2222222222222222222222222222222222222222',
      *         '0x3333333333333333333333333333333333333333',
      *         '0x4444444444444444444444444444444444444444'
      *         ];
      *
      * Merkle Root: 0x8ea0e3a5b1bcc3d21d094be4a529068bb97ef23671d5a18bc24c5ae11cffdbf7
      *     Proof for address: 0x1111111111111111111111111111111111111111 [
      *     '0x2ab0a4443bbea3fbe4d0e1503d11ff1367842fb0c8b28a5c8550f27599a40751',
      *     '0x0aafebc39b02f78812dd98aa2d43138e57bf2e2129476469fcffb7c1d572f346'
      *     ]
      */
```