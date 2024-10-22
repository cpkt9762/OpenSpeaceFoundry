// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "forge-std/console.sol";

contract NFTMarket is IERC721Receiver {
    struct Listing {
        address seller;
        uint256 price; // 价格
        bool isListed; // 是否挂牌
    }

    // NFT ID到挂牌信息的映射
    mapping(uint256 => Listing) public listings;

    IERC721 public nftContract; // NFT合约的引用
    IERC20 public tokenContract; // ERC20代币合约的引用

    constructor(address _nftContract, address _tokenContract) {
        nftContract = IERC721(_nftContract);
        tokenContract = IERC20(_tokenContract);
    }

    // NFT被挂牌时触发的事件
    event NFTListed(uint256 indexed nftId, address indexed seller, uint256 price);

    // NFT被购买时触发的事件
    event NFTBought(uint256 indexed nftId, address indexed buyer, uint256 price);

    // 获取NFT价格的函数
    function getNFTPrice(uint256 nftId) public view returns (uint256) {
        return listings[nftId].price;
    }


    // 在市场上列出NFT的函数
    // 支持设定任意ERC20价格来上架NFT
    function list(uint256 nftId, uint256 price) public {
        //断言重复上架
        require(listings[nftId].isListed == false, "NFT is already listed");
        require(nftContract.ownerOf(nftId) == msg.sender, "You must own the NFT to list it");
        require(price > 0, "Price must be greater than 0");
        // 将NFT转移到市场合约
        nftContract.transferFrom(msg.sender, address(this), nftId);

        // 为NFT创建一个挂牌
        listings[nftId] = Listing(msg.sender, price, true);
        emit NFTListed(nftId, msg.sender, price);
    }

    // 购买NFT的函数
    // 支持任意ERC20代币支付
    function buyNFT(address buyer, uint256 amount, uint256 nftId) public {
        Listing memory listing = listings[nftId];
        //You cannot buy your own NFT
        require(listing.seller != buyer, "You cannot buy your own NFT");

        require(tokenContract.balanceOf(buyer) >= amount, "Insufficient payment token balance");

        require(amount == listing.price, "Insufficient token amount to buy NFT");

        require(listing.isListed, "NFT not listed");

        // 从买家转移到卖家
        require(tokenContract.transferFrom(buyer, listing.seller, listing.price), "Token transfer failed");

        // 将NFT从市场转移到买家
        nftContract.transferFrom(address(this), buyer, nftId);

        // 标记NFT为已售出（取消挂牌）
        listings[nftId].isListed = false;

        emit NFTBought(nftId, buyer, listing.price);
    }

    // 取消NFT挂牌的函数（以防卖家想要撤回）
    function delist(uint256 nftId) public {
        Listing memory listing = listings[nftId];
        require(listing.isListed, "NFT is not listed");
        require(listing.seller == msg.sender, "Only the seller can delist the NFT");

        // 将NFT转回给卖家
        nftContract.transferFrom(address(this), msg.sender, nftId);

        // 移除挂牌
        delete listings[nftId];
    }

    // 实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能
    function tokensReceived(address from, address, uint256 amount, bytes calldata userData) external {
        require(msg.sender == address(tokenContract), "Only the ERC20 token contract can call this");
        uint256 nftId = abi.decode(userData, (uint256));
        Listing memory listing = listings[nftId];

        require(listing.price > 0, "NFT is not listed for sale");
        require(amount == listing.price, "Incorrect payment amount");

        // Transfer NFT to the buyer
        nftContract.safeTransferFrom(address(this), from, nftId);

        // Transfer the tokens to the seller
        tokenContract.transfer(listing.seller, amount);

        // Remove the listing
        delete listings[nftId];

        emit NFTBought(nftId, from, amount);
    }

    // Required for receiving NFTs
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
