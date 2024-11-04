// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RNT.sol";
import "./esRNT.sol";
import "forge-std/console.sol";
struct StakeInfo {
    // 质押数量
    uint256 staked;
    // 未领取奖励
    uint256 unclaimed;
    // 开始质押时间
    uint256  startTime;
}

contract StakePool is Ownable {
    RNT public rntToken;
    esRNT public esrntToken;
    mapping(address => StakeInfo) private stakes;
    //每质押1个RNT每天可奖励 1 esRNT;
    uint256 public rewardRate =  1 ether;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RedeemEsRNT(address indexed user, uint256 amount);

    constructor(RNT _rntToken,esRNT _esrntToken) Ownable(msg.sender) {
        rntToken = _rntToken;
        esrntToken=_esrntToken;
    }

  

    /*
    质押
    */
    function stake(uint256 amount) external {  
        require(amount > 0, "Amount must be greater than 0");
        //如果已经质押过，则不能再次质押
        require( stakes[msg.sender].staked==0, "already staked"); 
        rntToken.transferFrom(msg.sender, address(this), amount); 
        stakes[msg.sender].staked += amount; 
        stakes[msg.sender].startTime = block.timestamp;
        esrntToken.mint(msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    /*
    解押
    */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(stakes[msg.sender].staked >= amount, "Insufficient balance"); 
        stakes[msg.sender].staked -= amount;
        rntToken.transfer(msg.sender, amount); 
        emit Withdrawn(msg.sender, amount);
    }

    /*
    按时间计算奖励
    每质押1个RNT每天可奖励 1 esRNT;
    */
    function calculateReward(address user) private view returns (uint256) {
        StakeInfo storage stakeInfo = stakes[user];    
        uint256 dailyReward = rewardRate/1 days;
        return dailyReward * (block.timestamp - stakeInfo.startTime); 
    }

    /*
    领取奖励
    */
    function claim() external { 
       
        uint256 timeStaked = block.timestamp - stakes[msg.sender].startTime;  
        require(timeStaked < 30 days, "timeStaked must be less than 30 days");    
        uint256 reward = calculateReward(msg.sender); 
        require(reward > 0, "No reward to claim");
        require(esrntToken.balanceOf(address(this)) >= reward, "Insufficient balance");
       
        esrntToken.transfer(msg.sender, reward);
        stakes[msg.sender].unclaimed = 0;
        emit RewardClaimed(msg.sender, reward);
    }

    /*
    兑换 esRNT 为 RNT 
    */
    function redeemEsRNT() external {
        uint256 amount =calculateReward(msg.sender);
        //获取锁仓信息 
        require(amount > 0, "not enough token can be collection");  
        //判断是否超过30天
        if(block.timestamp - stakes[msg.sender].startTime >= 30 days){ 
            //1 esRNT 在 30 天后可兑换 1 RNT
            amount =  stakes[msg.sender].staked;
        }
        // 销毁 esRNT
        esrntToken.burn(msg.sender, amount); 

        // 转回 RNT 
        rntToken.transfer(msg.sender, amount); 

        emit RedeemEsRNT(msg.sender, amount);
    }
 

      /*
    获取质押信息
    */
    function getStakeInfo() external view returns (StakeInfo memory) {
        return stakes[msg.sender];
    }
}