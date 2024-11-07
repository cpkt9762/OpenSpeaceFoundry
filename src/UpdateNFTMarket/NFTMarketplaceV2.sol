// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTMarketplaceV1.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";  
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";
struct ListOrder { 
    address seller; // Seller
    address nft; // NFT address
    address payToken; // Pay token
    uint256 tokenId; // NFT tokenId 
    uint256 price; // Price
    uint256 deadline; // Deadline
    bytes32 orderId; // OrderId
} 
//必须继承自NFTMarketplaceV1
/// @custom:oz-upgrades-from NFTMarketplaceV1
contract NFTMarketplaceV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable { 
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); 
    mapping(address => mapping(uint256 => ListOrder)) private _lastIds; // NFT -> lastOrderId 
    mapping(bytes32 => ListOrder) private _orderIds;
   
    // NFT被挂牌时触发的事件
    event NFTListed(address indexed nft, uint256 indexed tokenId, address indexed seller, uint256 price);
    // NFT被购买时触发的事件
    event NFTBought(address indexed nft, uint256 indexed tokenId, address indexed buyer, uint256 price);
    
 
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    // 实现 `_authorizeUpgrade` 函数，只有合约拥有者可以升级合约
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

 
 
    /**
     * @notice 带签名上架NFT
     * @param nft NFT地址
     * @param tokenId NFT tokenId
     * @param payToken 支付token地址
     * @param price 价格
     * @param deadline 截止时间
     * @param signature 签名
     */
    function listNFTWithSignature( 
        address nft, 
        uint256 tokenId, 
        address payToken, 
        uint256 price, 
        uint256 deadline,
        bytes memory signature
        ) external {  

        // 构造上架订单
        ListOrder memory order = ListOrder(msg.sender, nft, payToken, tokenId, price, deadline, 0);

        // 签名
        bytes32 structHash = keccak256(abi.encode(msg.sender,order.nft, order.tokenId, order.payToken, order.price));
        bytes32 orderId =  MessageHashUtils.toEthSignedMessageHash(structHash);
        address signer = ECDSA.recover(orderId, signature);

        // 1. Check signature
        require(signer == msg.sender, "Invalid signature");
        // 2. Check owner
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "Not the owner");
        // 3. Check already listed
        require(_orderIds[orderId].seller == address(0), "Already listed"); 
        // 4. Check payToken
        require(order.payToken == ETH_FLAG || IERC20(order.payToken).totalSupply() > 0, "payToken is not valid");
        // 5. Check deadline
        require(order.deadline > block.timestamp, "deadline is in the past");
        // 6. Check price
        require(order.price > 0, "price is zero"); 
        // 7. Check approval
        require(
            IERC721(order.nft).getApproved(order.tokenId) == address(this)
                        || IERC721(order.nft).isApprovedForAll(msg.sender, address(this)),
            "not approved"
        );  
       
        order.orderId = orderId;

        // 带签名上架NFT
        _lastIds[nft][tokenId] = order; 
        _orderIds[orderId] = order;


        // 触发事件
        emit NFTListed(order.nft, order.tokenId, msg.sender, order.price);
    }
        
    /**
     * @notice 获取NFT上架信息
     * @param nft NFT地址
     * @param tokenId NFT tokenId
     */
    function listing(address nft, uint256 tokenId) external view returns (ListOrder memory) {
        return  _lastIds[nft][tokenId]; 
    } 

    /**
     * @notice 获取NFT上架信息
     * @param orderId 订单ID
     */
    function listing(bytes32 orderId) external view returns (ListOrder memory) {
        return  _orderIds[orderId];
    } 
    
    
    /**
     * @notice 购买NFT
     * @param orderId 订单ID
     */
    function buyNFT(bytes32 orderId) public payable { 
        ListOrder memory order = _orderIds[orderId]; 
        // 1. check
        require(order.seller != address(0), "Order not found");
        require(order.seller != msg.sender, "Seller cannot buy their own NFT");
        require(msg.value == order.price, "Incorrect payment");
        require(order.deadline > block.timestamp, "Order expired");  

        // 2. transfer
        IERC721(order.nft).transferFrom(order.seller, msg.sender, order.tokenId);
        payable(order.seller).transfer(msg.value);

        // 3. delete
        delete _orderIds[orderId];  
        delete _lastIds[order.nft][order.tokenId];

        // 4. emit event
        emit NFTBought(order.nft, order.tokenId, msg.sender, order.price);
    }  
    
    /**
     * @notice 获取版本
     */
    function version() external pure returns (string memory) {
        return "2";
    }
}
