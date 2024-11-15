// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../RNT/esRNT.sol";
import "forge-std/console.sol";
/**
 * 用Solidity编写ETH质押挖矿合约
 * 编写 StakingPool 合约，
 * 实现 Stake 和 Unstake 方法，
 * 允许任何人质押ETH来赚钱 KK Token。
 * 其中 KK Token 是每一个区块产出 10 个，
 * 产出的 KK Token 需要根据质押时长和质押数量来公平分配。
 */
//下面是合约接口信息
/**
 * @title KK Token
 */

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/**
 * @title Staking Interface
 */
interface IStaking {
    /**
     * @notice 质押 ETH 到合约
     */
    function stake() external payable;

    /**
     * @notice 赎回质押的 ETH
     * @param amount 赎回数量
     */
    function unstake(uint256 amount) external;

    /**
     * @notice 领取 KK Token 收益
     */
    function claim() external;

    /**
     * @notice 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice 获取待领取的 KK Token 收益
     * @param account 质押账户
     * @return 待领取的 KK Token 收益
     */
    function earned(address account) external view returns (uint256);
}
/**
 * @title Stake
 * @notice 质押池
 */

contract StakePoolV2 is Ownable {
    struct StakeInfo {
        // 质押数量
        uint256 staked;
        // 未领取奖励
        uint256 unclaimed;
        // 质押时长
        uint256 startTime;
        // 开始质押区块number
        uint256 startBlockNumber;
    }

    esRNT public kkToken;

    mapping(address => StakeInfo) private stakes;
    //每质押1个eth每天可奖励 1 esRNT;
    uint256 public rewardRate = 1 ether;
    uint256 public totalStaked; // 全网总质押量
    uint256 public constant REWARD_PER_BLOCK = 10; // 每区块奖励 10 个 KK Token

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);
    event RedeemEsRNT(address indexed user, uint256 amount);

    constructor(esRNT _esrntToken) Ownable(msg.sender) {
        kkToken = _esrntToken;
        totalStaked = 0;
    }

    /*
    质押
    */
    receive() external payable {}

    function stake() external payable {
        require(msg.value > 0, "Staking amount must be greater than zero");

        StakeInfo storage stakeInfo = stakes[msg.sender];

        // 更新之前的奖励
        uint256 pendingReward = calculateReward(msg.sender);
        stakeInfo.unclaimed += pendingReward;
        console.log("pendingReward", pendingReward);
        // 更新质押信息
        stakeInfo.staked += msg.value;
        //需要判断是否已经质押过
        if (stakeInfo.startTime == 0) {
            stakeInfo.startTime = block.timestamp;
            stakeInfo.startBlockNumber = block.number;
        }

        totalStaked += msg.value;
        // (bool success,) = address(this).call{value: msg.value}("");
        // require(success, "Transfer failed");
        emit Staked(msg.sender, msg.value);
    }

    /*
    解押
    */
    function unstake(uint256 amount) external {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.staked >= amount, "Insufficient staked amount");

        // 计算奖励
        uint256 reward = calculateReward(msg.sender);
        stakeInfo.unclaimed += reward;

        // 更新质押信息
        stakeInfo.staked -= amount;
        stakeInfo.startTime = block.timestamp;
        stakeInfo.startBlockNumber = block.number;

        totalStaked -= amount;

        // 发送奖励和 ETH
        uint256 totalReward = stakeInfo.unclaimed;
        stakeInfo.unclaimed = 0;
        // 铸造totalReward 个 KK Token
        kkToken.mint(address(this), totalReward);
        // 转给用户
        kkToken.transfer(msg.sender, totalReward);
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, amount, totalReward);
    }

    /* 
    *按时间计算奖励
    *每质押1个RNT每天可奖励 1 esRNT;
    *KK Token 是每一个区块产出 10 个，
    *产出的 KK Token 需要根据质押时长和质押数量来公平分配。 
    */
    function calculateReward(address user) public view returns (uint256) {
        StakeInfo storage stakeInfo = stakes[user];
        if (stakeInfo.staked == 0) {
            return stakeInfo.unclaimed;
        }

        uint256 blocksStaked = block.number - stakeInfo.startBlockNumber;
        uint256 userShare = ((stakeInfo.staked - totalStaked) * 1e18) / totalStaked / 1e18; // 用户质押占比（放大精度）
        uint256 totalReward = blocksStaked * REWARD_PER_BLOCK;

        //如果用户质押占比大于0，则计算用户奖励
        if (userShare > 0) {
            return (totalReward * userShare) + stakeInfo.unclaimed;
        }
        return totalReward + stakeInfo.unclaimed;
    }

    /*
    * 领取奖励
    */
    function claim() external {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        uint256 reward = calculateReward(msg.sender);

        require(reward > 0, "No reward to claim");

        stakeInfo.unclaimed = 0;
        stakeInfo.startTime = block.timestamp;
        stakeInfo.startBlockNumber = block.number;

        // 铸造reward 个 KK Token
        kkToken.mint(address(this), reward);
        // 转给用户
        kkToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @notice 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256) {
        return stakes[account].staked;
    }

    /**
     * @notice 获取待领取的 KK Token 收益
     * @param account 质押账户
     * @return 待领取的 KK Token 收益
     */
    function earned(address account) external view returns (uint256) {
        return stakes[account].unclaimed;
    }

    /*
    兑换 esRNT 为 ETH
    */
    function redeemEsRNT() external {
        uint256 amount = calculateReward(msg.sender);
        //获取锁仓信息
        require(amount > 0, "not enough token can be collection");

        // 销毁 esRNT
        kkToken.burn(msg.sender, amount);

        // 转回 RNT
        payable(msg.sender).transfer(amount);

        emit RedeemEsRNT(msg.sender, amount);
    }

    /*
    获取质押信息
    */
    function getStakeInfo() external view returns (StakeInfo memory) {
        return stakes[msg.sender];
    }
}
