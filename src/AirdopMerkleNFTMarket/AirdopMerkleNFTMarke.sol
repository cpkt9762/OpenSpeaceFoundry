// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
组合使用 MerkleTree 白名单、 Permit 授权 及 Multicall

题目#1
实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：

基于 Merkel 树验证某用户是否在白名单中
在白名单中的用户可以使用上架（和之前的上架逻辑一致）指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。
要求使用 multicall( delegateCall 方式) 一次性调用两个方法：

permitPrePay() : 调用token的 permit 进行授权
claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 。
 */

contract AirdropMerkleNFTMarke {
    using Address for address;

    address public token; // Discount token with permit support
    IERC721 public nft; // NFT contract
    bytes32 public merkleRoot; // Merkle root for whitelist

    struct ListedNFT {
        uint256 price;
        address seller;
        uint256 tokenId;
        uint256 deadline;
    }

    mapping(uint256 => ListedNFT) public tokenId2NFT; // tokenId => NFT

    event Claimed(address indexed user);

    constructor(address _token, address _nft, bytes32 _merkleRoot) {
        token = _token;
        nft = IERC721(_nft);
        merkleRoot = _merkleRoot;
    }

    // Verify if an address is in the Merkle whitelist
    function isWhitelisted(address user, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /*
    上架
    */
    function list(uint256 tokenId, uint256 price, uint256 deadline) public {
        tokenId2NFT[tokenId] = ListedNFT(price, msg.sender, tokenId, deadline);
    }

    /**
     * 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT
     * 验证白名单
     * 验证默克尔树
     * 转移 nft
     * 转移 token
     */
    function claimNFT(uint256 nftId, address spender, bytes32[] calldata proof) public returns (bool) {
        require(isWhitelisted(spender, proof), "Not in whitelist");

        uint256 discountedPrice = tokenId2NFT[nftId].price / 2;
        // 转入 token
        IERC20(token).transfer(spender, discountedPrice);

        // 转出 nft
        nft.transferFrom(tokenId2NFT[nftId].seller, spender, nftId);

        // 事件
        emit Claimed(spender);

        return true;
    }

    // Authorize token transfer using permit
    //permitPrePay() : 调用token的 permit 进行授权
    /**
     * 验证价格是否足够
     * 验证 nft 没有卖出
     * 授权
     * 转入 token
     */
    function permitPrePay(
        address owner,
        address spender,
        uint256 tokenId,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // 验证价格是否足够
        require(amount >= tokenId2NFT[tokenId].price / 2, "low price");
        // 验证 nft 没有卖出
        require(nft.ownerOf(tokenId) != address(this), "aleady selled");

        // 授权
        IERC20Permit(token).permit(owner, spender, tokenId, deadline, v, r, s);
    }

    // Multicall function to execute permit and purchase in a single transaction
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success, "Multicall execution failed");
            results[i] = result;
        }
        return results;
    }
}
