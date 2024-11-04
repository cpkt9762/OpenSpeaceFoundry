// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
质押挖矿合约，实现如下功能： 
1 用户随时可以质押项目方代币 RNT(自定义的ERC20) ，开始赚取项目方Token(esRNT)；
2 可随时解押提取已质押的 RNT；
3 可随时领取esRNT奖励，每质押1个RNT每天可奖励 1 esRNT;
4 esRNT 是锁仓性的 RNT， 1 esRNT 在 30 天后可兑换 1 RNT，随时间线性释放，支持提前将 esRNT 兑换成 RNT，但锁定部分将被 burn 燃烧掉。
*/
contract Staking is Ownable {
    IERC20 public rntToken; // RNT 主代币
    IERC20 public esRntToken; // esRNT 质押奖励代币

    uint256 public rewardRate = 1 ether; // 每秒奖励 1 esRNT
    uint256 public lastUpdateTime;
    // 用户地址 => 奖励数量
    mapping(address => uint256) public rewards;
    // 用户地址 => 质押数量
    mapping(address => uint256) public userStakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    /*
    @param _rntToken RNT 主代币
    @param _esRntToken esRNT 质押奖励代币
    */
    constructor(IERC20 _rntToken, IERC20 _esRntToken) Ownable(msg.sender) {
        rntToken = _rntToken;
        esRntToken = _esRntToken;
    }

    /*
    质押
    */
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero");
        updateReward(msg.sender);
        userStakes[msg.sender] += amount;
        rntToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /*
    提取
    */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw zero");
        require(userStakes[msg.sender] >= amount, "Insufficient stake");
        updateReward(msg.sender);
        userStakes[msg.sender] -= amount;
        rntToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /*
    领取奖励
    */
    function claimReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        rewards[msg.sender] = 0;
        esRntToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /*
    更新奖励
    */
    function updateReward(address account) internal {
        rewards[account] += userStakes[account] * (block.timestamp - lastUpdateTime) * rewardRate;
        lastUpdateTime = block.timestamp;
    }

    /*
    解锁 esRNT
    */
    function unlockEsRNT(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(esRntToken.balanceOf(msg.sender) >= amount, "Insufficient esRNT balance");
        esRntToken.transferFrom(msg.sender, address(this), amount);
        rntToken.transfer(msg.sender, amount); // 解锁 esRNT 为 RNT
    }

    /*
    设置奖励率
    */
    function setRewardRate(uint256 rate) external onlyOwner {
        rewardRate = rate;
    }
}
