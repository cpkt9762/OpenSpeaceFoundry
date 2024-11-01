// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";    
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; 
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "forge-std/console.sol";

contract MyERC20Token is  Initializable,ERC20Upgradeable {
 
    address public factory; 
    uint public totalSupplyToken;
    uint public perMint;
 
    /**
     * @dev 初始化函数
     * @param _symbol 符号
     * @param _totalSupply 总供应量
     * @param _perMint 每次发行数量
     * @param _factory 工厂地址
     */
    function initialize(string memory _symbol, uint _totalSupply, uint _perMint, address _factory) public initializer {
        require(factory == address(0), "Already initialized"); 
        __ERC20_init("ERC20Token", _symbol);  
        perMint = _perMint;
        factory = _factory;
        totalSupplyToken = _totalSupply;
    }

    function mint(address to) external {
        require(msg.sender == factory, "Only factory can mint");
        uint currentSupply = totalSupply(); 
         require(
            currentSupply + perMint <= totalSupplyToken,
            "Exceeds max total supply"
        ); 
        _mint(to, perMint); 
    }
}


contract TokenFactoryV1 is  UUPSUpgradeable, OwnableUpgradeable {
    mapping(address => address) public tokenToDeployer;
     address public implementation;


   function initialize(address _owner) public initializer {
        __Ownable_init(_owner); 
    }


    /**
     * @dev 部署ERC20 token (模拟铭文的 deploy)
     * @param symbol 符号
     * @param totalSupply 总供应量
     * @param perMint 每次发行数量
     */
    function deployInscription(string memory symbol, uint256 totalSupply, uint256 perMint) external returns (address) {
        //合约的第⼀版本用普通的 new 的方式发行 ERC20 token
        MyERC20Token token = new MyERC20Token();
        token.initialize(symbol, totalSupply, perMint, address(this));
        tokenToDeployer[msg.sender] = address(token);

        return address(token);
    }
    /**
     * @dev 发行ERC20 token (每次调用一次，发行perMint指定的数量)
     * @param tokenAddr 铭文地址
     */
    function mintInscription(address tokenAddr) external virtual payable { 
        //onlyOwner 
        require(tokenToDeployer[msg.sender] == tokenAddr, "Not the deployer");
        
        MyERC20Token(tokenAddr).mint(msg.sender); 
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}


    function upgradeTo(address newImplementation) public  {
        require(msg.sender == owner(), "Only owner can upgrade");
        implementation = newImplementation;
    }

      function getDeployedToken(address deployer) public view returns (address) {
        return tokenToDeployer[deployer];
    }
}


 
contract TokenFactoryV2 is TokenFactoryV1  { 
    mapping(address => uint) public tokenPrices;   
    constructor() {
        implementation = address(new MyERC20Token());
    }
    /**
     * @dev 部署ERC20 token (模拟铭文的 deploy)
     * @param _symbol 符号
     * @param totalSupply 总供应量
     * @param perMint 每次发行数量
     * @param price 价格
     */
    function deployInscription(
        string memory _symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address) {
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        require(totalSupply > 0, "Total supply must be greater than zero");
        require(perMint > 0, "Per mint must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        require(
            address(implementation) != address(0),
            "Implementation address is not set"
        );
        address clone = Clones.clone(implementation);
        MyERC20Token(clone).initialize(
            _symbol,
            totalSupply,
            perMint,
            address(this)
        );
        tokenToDeployer[clone] = msg.sender;
        tokenPrices[clone] = price;

        return clone;
    }

    /**
     * @dev 发行ERC20 token (每次调用一次，发行perMint指定的数量)
     * @param tokenAddr 铭文地址
     */
   function mintInscription(address tokenAddr) external override payable  { 
        //onlyOwner 
        require(tokenToDeployer[msg.sender] == tokenAddr, "Not the deployer");
    
        uint price = tokenPrices[tokenAddr];
        require(msg.value >= price, "Insufficient payment");
        MyERC20Token(tokenAddr).mint(msg.sender);

         console.log("msg.value", msg.value);
        console.log("address(this)", address(this));
        console.log("msg.sender", msg.sender);
        console.log("owner()", owner());
        console.log("balanceOf", MyERC20Token(tokenAddr).balanceOf(address(this)));
        console.log("balanceOf(msg.sender)", MyERC20Token(tokenAddr).balanceOf(msg.sender));
        console.log("tokenAddr", tokenAddr);

        // 将支付的费用转给合约的接收者（可以是合约的所有者或者指定的地址）
        address payable receiver = payable(owner());
        receiver.transfer(msg.value);

    }

    // 允许提取工厂合约的资金
    function withdraw() external {
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(msg.sender).transfer(balance);
    }
   
}
