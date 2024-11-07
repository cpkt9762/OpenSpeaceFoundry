const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

// 白名单用户地址
const whitelist = [
  '0x1111111111111111111111111111111111111111',
  '0x2222222222222222222222222222222222222222',
  '0x3333333333333333333333333333333333333333',
  '0x4444444444444444444444444444444444444444'
];

// 将地址哈希化以便用于生成Merkle树
const leafNodes = whitelist.map(addr => keccak256(addr));
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

// 计算Merkle树根
const merkleRoot = merkleTree.getHexRoot();
console.log('Merkle Root:', merkleRoot);

// 为特定地址生成证明路径
const claimingAddress = '0x1111111111111111111111111111111111111111';
const proof = merkleTree.getHexProof(keccak256(claimingAddress));
console.log('Proof for address:', claimingAddress, proof);
