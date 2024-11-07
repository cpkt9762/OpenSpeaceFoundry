// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    constructor(
        uint256 minDelay,                  // 延迟时间（秒）
        address[] memory proposers,        // 提案者角色地址
        address[] memory executors,        // 执行者角色地址
        address admin                      // 管理员地址
    ) 
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
