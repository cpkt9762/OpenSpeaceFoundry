# NFT Marketplace Upgradeable Contracts

This repository contains the code for an upgradable NFT marketplace on Ethereum.

### Contracts

- **Proxy Contract Address**: [Proxy Contract on Sepolia](https://sepolia.etherscan.io/address/0x95D7ae5b5D90a4a9a6BcC707A2E7216D0599a9f3)
- **NFT Marketplace V1 Address**: [NFTMarketplaceV1 on Sepolia](https://sepolia.etherscan.io/address/0x84B569ed099c67cf8fF76Cf72dAb24d95B8FA737)
- **NFT Marketplace V2 Address**: [NFTMarketplaceV2 on Sepolia](https://sepolia.etherscan.io/address/0xa827d08bb44eb4381c2acf1d291431edd8834cc7)

### Features

- **NFT Marketplace V1**: 基础市场功能，包括上架和购买。
- **NFT Marketplace V2**: 添加了通过离线签名上架NFT的功能，允许用户通过单次授权上架NFT。




```bash
forge clean&&forge test -vvvvv  --match-path test/UpdateNFTMarket/NFTMarketplaceTest.t.sol --ffi
```

// v2中必须有以下注释
/// @custom:oz-upgrades-from NFTMarketplaceV1
// @custom:oz-upgrades-from NFTMarketplaceV1：告诉 OpenZeppelin 插件，NFTMarketplaceV2 是从 NFTMarketplaceV1 继承而来。
// 这使得插件在验证时将 NFTMarketplaceV1 作为升级的基准合约。


test/UpdateNFTMarket/NFTMarketplaceTest.t.sol 中测试了 V2 版本中上架 NFT 的功能。