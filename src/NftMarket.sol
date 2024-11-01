pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";  
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol"; 

struct ListOrder { 
    address nft;
    uint256 tokenId;
    address payToken;
    uint256 price;
    uint256 deadline;
}

struct Listing {
    address seller; // Seller
    address nft; // NFT address
    uint256 tokenId; // NFT tokenId
    address payToken; // Payment token address
    uint256 price; // Price
    uint256 deadline; // Deadline
    bool isListed; // Is listed
    uint256 index;
}
contract ListingMapKeys {
    mapping(bytes32 => Listing)  private _data;
    bytes32[] private _keys;
    
    function setValue(bytes32 key, Listing memory value) external {
      
        if (!exists(key)) {
            _keys.push(key);
            value.index = _keys.length - 1;
              _data[key] = value;
        }
      
    }
    function getValue(bytes32 key) external view returns (Listing memory) {
        return _data[key];
    }
    //Delist 
    function delList(bytes32 key) external {
        _data[key].isListed = false; 
        delete _keys[_data[key].index];
        delete  _data[key];
    }
    function exists(bytes32 key) public view returns (bool) {
        return _data[key].isListed;
    }
    
    function getAllKeys() public view returns (bytes32[] memory) {
        return _keys;
    }
} 
contract NftMarket is Ownable, IERC721Receiver,  EIP712 { 

  
    bytes32 public constant _ORDER_TYPEHASH = keccak256("ListOrder(address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)");
    // Mapping from NFT ID to listing information
    ListingMapKeys public listingOrders; 
    Listing[] public totalOrders;
    mapping(address => mapping(uint256 => bytes32)) private _lastIds; // NFT -> lastOrderId
    mapping(address => bool) public whitelist;
    address public feeCollector;
    uint256 public platformFee = 30; // Example platform fee as // 30/10000 = 0.3%
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    constructor(address _feeCollector) EIP712("NftMarket", "1") Ownable(msg.sender) { 
        feeCollector = _feeCollector;
        totalOrders = new Listing[](0);
    }
  
    function recoverAddress(bytes memory signature, bytes32 msgHash) public returns(address recovered){
    
        bytes32 _message = MessageHashUtils.toEthSignedMessageHash(msgHash);
        recovered = ECDSA.recover(_message, signature);
        return recovered;
    }

    //getAllOrders 
    function getAllOrders() public view returns (Listing[] memory) { 
        uint256 listedCount = 0;
        for (uint256 i = 0; i < totalOrders.length; i++) {
            if (totalOrders[i].isListed) {
                listedCount++;
            }
        }

        Listing[] memory orders = new Listing[](listedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < totalOrders.length; i++) {
            if (totalOrders[i].isListed) {
                orders[index] = totalOrders[i];
                index++;
            }
        }
        return orders;
    }
    function listing(address nft, uint256 tokenId) external view returns (bytes32) {
        bytes32 id = _lastIds[nft][tokenId];
        Listing memory listorder = listingOrders.getValue(id);
        if (listorder.isListed) {
            return id;
        } else {
            return bytes32(0x00);
        }
    } 

    function hashTypedData(bytes32 structHash) public view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }

    function  buildDomainSeparator() public view  returns (bytes32) {
        return _domainSeparatorV4();
    }
    function orderHash(ListOrder memory order) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(
            _ORDER_TYPEHASH,  
            order.nft,
            order.tokenId,
            order.payToken,
            order.price,
            order.deadline 
        )); 
        // Generate the final hash that complies with EIP712
        return _hashTypedDataV4(structHash); 
    }

    // 1. Sign a listing off-chain with seller's signature, then verify and store it on-chain.
    function listNFT(
        ListOrder calldata order,
        bytes memory signature
    ) external { 
        bytes32 orderId = orderHash(order); 
        address signer;
        if (order.payToken == ETH_FLAG){
            signer = ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(orderId), signature); 
        } else {
            signer = ECDSA.recover(MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), orderId), signature); 
        }
        
        // 1. Check signature
        require(signer == msg.sender, "Invalid signature");
        // 2. Check owner
        require(IERC721(order.nft).ownerOf(order.tokenId) == msg.sender, "Not the owner");
        // 3. Check already listed
        require(listingOrders.getValue(orderId).isListed == false, "Already listed"); 
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
        listingOrders.setValue(orderId, Listing({
            nft: order.nft,
            tokenId: order.tokenId,
            seller: msg.sender,
            payToken: order.payToken,
            price: order.price,
            deadline: order.deadline,
            isListed: true,
            index: 0
        }));
        _lastIds[order.nft][order.tokenId] = orderId; 
        emit List(order.nft, order.tokenId, orderId, msg.sender, order.payToken, order.price, order.deadline);
    }
  

    // Function to get the NFT price
    function getNFTPrice(bytes32 orderId) public view returns (uint256) {
        return listingOrders.getValue(orderId).price;
    }
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }       
    function _transferOut(address token, address to, uint256 amount) private { 
        if (token == ETH_FLAG) {  
            // Transfer ETH to the recipient
            safeTransferETH(to, amount);  
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, to, amount);
        }
    }
    // Function to buy NFT
    // Supports payment with any ERC20 token
    function buyNFT(bytes32 orderId) public payable { 
        Listing memory listorder = listingOrders.getValue(orderId);
        // 1. Check seller != buyer
        require(listorder.seller != msg.sender, "You cannot buy your own NFT"); 
        // 2. Check balance
        if(listorder.payToken == ETH_FLAG){
            require(msg.sender.balance >= listorder.price, "Insufficient payment token balance"); 
        } else {
            require(IERC20(listorder.payToken).balanceOf(msg.sender) >= listorder.price, "Insufficient payment token balance"); 
        }
        // 3. Check listed
        require(listorder.isListed, "NFT not listed"); 

        // 4. Check deadline
        require(listorder.deadline > block.timestamp, "deadline is in the past");

        // Fee 0.3% or 0
        uint256 fee =  listorder.price * platformFee / 10000;
        
        // Safe check
        if (listorder.payToken == ETH_FLAG) {
            require(msg.value >= (listorder.price + fee), "MKT: wrong eth value");
        } else {
            require(msg.value == 0, "MKT: wrong eth value");
        }

        // 3. Transfer NFT
        IERC721(listorder.nft).safeTransferFrom(listorder.seller, msg.sender, listorder.tokenId); 
        // 4. Transfer price
        _transferOut(listorder.payToken, listorder.seller, listorder.price - fee);

        if(fee > 0){
            _transferOut(listorder.payToken, feeCollector, fee);
        } 

        // 8. Delist 
        listingOrders.delList(orderId); 
 

        emit Sold(orderId, msg.sender, listorder.price); 
    }

    // Function to cancel NFT listing (in case the seller wants to withdraw)
    function delist(bytes32 orderId) public {
        Listing memory listorder = listingOrders.getValue(orderId);
        require(listorder.isListed, "NFT is not listed");
        require(listorder.seller == msg.sender, "Only the seller can delist the NFT");

        // Transfer NFT back to the seller
        IERC721(listorder.nft).safeTransferFrom(address(this), msg.sender, listorder.tokenId);

        // Remove listing
        listingOrders.delList(orderId);
    }

    // Implement the tokensReceived method required for ERC20 extension tokens, 
    // and implement NFT purchase functionality in tokensReceived
    function tokensReceived(address from, address, uint256 amount, bytes calldata userData) external { 
        bytes32 orderId = abi.decode(userData, (bytes32));
        Listing memory listorder = listingOrders.getValue(orderId);

        require(listorder.price > 0, "NFT is not listed for sale");
        require(amount == listorder.price, "Incorrect payment amount");

        // Transfer NFT to the buyer
        IERC721(listorder.nft).safeTransferFrom(address(this), from, listorder.tokenId);

        // Transfer the tokens to the seller
        IERC20(listorder.payToken).transfer(listorder.seller, amount);

        // Remove the listing
        listingOrders.delList(orderId);

        emit NFTBought(orderId, from, amount);
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


    // Use permit function for purchase
    function permitBuy( 
        bytes32 listingId,
        uint256 amount,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, listingId, amount, deadline, nonce)); 
        address signer = ecrecover(hash, v, r, s); 
        require(signer == msg.sender, "Invalid signature");  
        Listing memory listorder = listingOrders.getValue(listingId);
        // Deduct tokens for purchase
        IERC20(listorder.payToken).transferFrom(msg.sender, address(this), amount);
        IERC721(listorder.nft).safeTransferFrom(address(this), msg.sender, listorder.tokenId);
 
    } 

    event List(
            address indexed nft,
            uint256 indexed tokenId,
            bytes32 orderId,
            address seller,
            address payToken,
            uint256 price,
            uint256 deadline
        ); 
    event Sold(bytes32 orderId, address buyer, uint256 fee);

    // Event triggered when NFT is purchased
    event NFTBought(bytes32 orderId, address indexed buyer, uint256 price);  
}
