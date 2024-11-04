// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

  
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";
/*
编写 IDO 合约，实现 Token 预售，需要实现如下功能： 
开启预售: 支持对给定的任意ERC20开启预售，设定预售价格，募集ETH目标，超募上限，预售时长。
任意用户可支付ETH参与预售；
预售结束后，如果没有达到募集目标，则用户可领会退款；
预售成功，用户可领取 Token，且项目方可提现募集的ETH；
*/
contract IDO is ReentrancyGuard, Ownable {
    IERC20 public token;//预售的代币
    uint256 public price;//预售价格
    uint256 public target;//预售目标
    uint256 public cap;//预售上限
    uint256 public duration;//预售时长
    uint256 public startTime;//预售开始时间 
    // 贡献者地址 => 贡献金额
    mapping(address => uint256) public contributions;
    // 贡献者地址 => 购买代币数量
    mapping(address => uint256) public purchasedTokens;
    // 预售是否结束
    bool public finalized;
    // 是否达到目标
    bool public targetReached;

    event PresaleStarted(IERC20 token, uint256 price, uint256 target, uint256 cap, uint256 duration);
    event Contribution(address indexed user, uint256 amount);
    event Refund(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 amount);
    event WithdrawETH(address indexed owner, uint256 amount);

    modifier onlyDuringPresale() {
        require(block.timestamp >= startTime && block.timestamp <= startTime + duration, "Presale not active");
        _;
    }

    modifier onlyAfterPresale() {
        console.log("block.timestamp", block.timestamp);
        console.log("startTime + duration", startTime + duration);
        require(block.timestamp > startTime + duration, "Presale not ended");
        _;
    } 
 
    /*
    @param _token 预售的代币
    @param _price 预售价格
    @param _target 预售目标
    @param _cap 预售上限
    @param _duration 预售时长
    */
   constructor(
        IERC20 _token,
        uint256 _price,
        uint256 _target,
        uint256 _cap,
        uint256 _duration
    ) Ownable(msg.sender) ReentrancyGuard() {
        require(startTime == 0, "Presale already started");
        token = _token;
        price = _price;
        target = _target;
        cap = _cap;
        startTime = block.timestamp;
        duration =  _duration;
        emit PresaleStarted(_token, _price, _target, _cap, _duration);
    }

    /*
    贡献ETH
    */
    function contribute() external payable onlyDuringPresale {
        require(address(this).balance <= cap, "Cap exceeded");
        _purchase(msg.sender, msg.value);
        emit Contribution(msg.sender, msg.value);
    }

    /*
    退款
    */
    function withdraw() external onlyAfterPresale {
        require(!targetReached, "Target reached, no refund");
        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        purchasedTokens[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
        emit Refund(msg.sender, refundAmount);
    }

    /*
    领取代币
    */
    function claimTokens() external onlyAfterPresale {
        require(targetReached, "Target not reached");
        uint256 tokens = purchasedTokens[msg.sender];
        purchasedTokens[msg.sender] = 0;
        token.transfer(msg.sender, tokens);
        emit TokensClaimed(msg.sender, tokens);
    }

    /*
    提取ETH
    */
    function withdrawETH() external onlyOwner onlyAfterPresale {
        require(targetReached, "Target not reached");
        uint256 balance = address(this).balance; 
        payable(owner()).transfer(balance); 
        emit WithdrawETH(owner(), balance);
    }

    /*
    结束预售
    */
    function finalize() external onlyOwner {
        if (address(this).balance >= target) {
            targetReached = true;
        }
        finalized = true;
    }

    /*
    购买代币
    */
    function _purchase(address _address, uint256 _amount) private {
        contributions[_address] += _amount;
        uint256 tokenAmount = (_amount * 10**18) / price;
        purchasedTokens[_address] += tokenAmount; 
    }

    receive() external payable {
        _purchase(msg.sender, msg.value);
    }
}
