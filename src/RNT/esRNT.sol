// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 锁仓信息
struct LockInfo {
    address user;
    uint256 amount;
    uint256 lockTime;
    uint256 unlockTime;
    bool isBurned;
}

contract esRNT is ERC20, Ownable {
    // 用户地址 => 锁仓信息
    mapping(address => LockInfo) private locksInfos;

    event Minted(address indexed _user, uint256 _amount, uint256 lockTime);
    event Burned(address indexed _user, uint256 _amount, uint256 unlockTime);

    constructor() ERC20("Escrowed Reward Token", "esRNT") Ownable(msg.sender) {
        _transferOwnership(msg.sender);
    }

    //重写 transferFrom
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(locksInfos[from].lockTime > 0, "No lock found");
        return false;
    }

    /*
    铸造 esRNT
    */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        locksInfos[to] = LockInfo({
            user: to,
            amount: amount,
            lockTime: block.timestamp,
            unlockTime: block.timestamp + 30 days,
            isBurned: false
        });

        emit Minted(to, amount, block.timestamp);
    }

    /*
    销毁 esRNT
    */
    function burn(address user, uint256 amount) public {
        require(locksInfos[user].lockTime > 0, "No lock found");
        LockInfo storage lock = locksInfos[user];
        _burn(user, lock.amount);
        lock.amount -= amount;
        lock.unlockTime = block.timestamp;
        lock.isBurned = true;
        emit Burned(user, amount, block.timestamp);
    }

    /*
    获取用户锁仓信息
    */
    function getLocksByUser(address user) external view returns (LockInfo memory) {
        return locksInfos[user];
    }
}
