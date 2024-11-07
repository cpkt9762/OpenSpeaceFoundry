// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract NFTMarketplaceV1 is  Initializable, UUPSUpgradeable, OwnableUpgradeable { 

    struct ListOrder { 
        address seller; // Seller
        address nft; // NFT address
        address payToken; // Pay token
        uint256 tokenId; // NFT tokenId 
        uint256 price; // Price
        uint256 deadline; // Deadline 
    }
    mapping(address => mapping(uint256 => ListOrder)) private _lastIds;


    // NFT被挂牌时触发的事件
    event NFTListed(uint256 indexed nftId, address indexed seller, uint256 price);
    // NFT被购买时触发的事件
    event NFTBought(uint256 indexed nftId, address indexed buyer, uint256 price);
 
 
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

     
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice 允许用户一次性授权NFT市场合约管理其所有NFT
     * @param nft NFT地址
     * @param operator 授权地址
     * @param approved 授权状态
     */
    function setApproveAll(address nft, address operator, bool approved) external {
        IERC721(nft).setApprovalForAll(operator, approved);
    }
 
    /**
     * @notice 上架NFT
     * @param nft NFT地址
     * @param payToken 支付token地址
     * @param tokenId NFT tokenId
     * @param price 价格
     */
    function listNFT(address nft,address payToken,uint256 tokenId, uint256 price) external { 
        _lastIds[nft][tokenId] = ListOrder(msg.sender, nft, payToken, tokenId, price, block.timestamp + 1 days);
        emit NFTListed(tokenId, msg.sender, price);
    }
     
    /**
     * @notice 购买NFT
     * @param nft NFT地址
     * @param tokenId NFT tokenId
     */
    function buyNFT(address nft, uint256 tokenId) public payable {
        require(msg.value == _lastIds[nft][tokenId].price, "Incorrect payment");
        IERC721(nft).transferFrom(owner(), msg.sender, tokenId);
        payable(owner()).transfer(msg.value);
        delete _lastIds[nft][tokenId];
        emit NFTBought(tokenId, msg.sender, _lastIds[nft][tokenId].price);
    }  
        
    /**
     * @notice 获取NFT上架信息
     */
    function listing(address nft, uint256 tokenId) external view returns (ListOrder memory) {
        ListOrder memory id = _lastIds[nft][tokenId].seller != address(0) ? _lastIds[nft][tokenId] : ListOrder(address(0), address(0), address(0), 0, 0, 0);
        return id;
    }  

    /**
     * @notice 获取版本
     */
    function version() external pure returns (string memory) {
        return "1";
    }
} 
