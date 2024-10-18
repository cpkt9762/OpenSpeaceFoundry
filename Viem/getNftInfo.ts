import { createPublicClient, http, parseEther } from 'viem';
import { mainnet } from 'viem/chains';
import { abi as ERC721Abi } from '@openzeppelin/contracts/build/contracts/ERC721.json';

const client = createPublicClient({
  chain: mainnet,
  transport: http(),
});

// NFT 合约地址
const nftContractAddress = '0x0483b0dfc6c78062b9e999a82ffb795925381415';
// 要查询的 NFT ID
const tokenId = 1; // 替换为你要查询的 NFT ID
//读取 NFT 的持有人地址。
async function getNftOwner() {
  try {
    const owner = await client.readContract({
      address: nftContractAddress,
      abi: ERC721Abi,
      functionName: 'ownerOf',
      args: [tokenId],
    });

    console.log(`NFT ${tokenId} 的持有人地址: ${owner}`);
  } catch (error) {
    console.error('获取持有人地址失败:', error);
  }
}
//读取指定 NFT 的元数据地址。
async function getTokenURI() {
  try {
    const tokenURI = await client.readContract({
      address: nftContractAddress,
      abi: ERC721Abi,
      functionName: 'tokenURI',
      args: [tokenId],
    });

    console.log(`NFT ${tokenId} 的元数据地址: ${tokenURI}`);
  } catch (error) {
    console.error('获取元数据失败:', error);
  }
}
 
getNftOwner();
getTokenURI();

