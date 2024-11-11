// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "forge-std/console.sol";
/*
*先实现一个 Bank 合约，
*用户可以通过 deposit() 存款， 
*然后使用 ChainLink Automation 、Gelato 或 OpenZepplin Defender Action 实现一个自动化任务，
*自动化任务实现：
*当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。
 */

contract Bank is AutomationCompatibleInterface {
    address public owner; // Owner address to receive excess funds
    uint256 public threshold; // Threshold for automated transfers
    uint256 public totalDeposits; // Track total deposits to avoid repeated automation runs

    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event ThresholdUpdated(uint256 newThreshold);
    event OwnerChanged(address indexed newOwner);
    event HalfBalanceTransferred(address indexed owner, uint256 amount);

    constructor(uint256 _threshold) {
        owner = msg.sender;
        threshold = _threshold;
    }

    /*
    * Deposit function for users
    */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    /*
    * Check if the balance is greater than the threshold
    */

    function checkUpkeep(bytes calldata /* checkData */ )
        external
        view
        override
        returns (bool shouldTransferFunds, bytes memory /* performData */ )
    {
        shouldTransferFunds = (address(this).balance > threshold);
        return (shouldTransferFunds, "");
    }

    /*
    * Perform the transfer of half the balance to the owner
    */
    function performUpkeep(bytes calldata /* performData */ ) external override {
        if (address(this).balance > threshold) {
            uint256 halfBalance = address(this).balance / 2;

            (bool success,) = payable(owner).call{value: halfBalance}("");
            require(success, "Transfer failed");
            emit HalfBalanceTransferred(owner, halfBalance);
        }
    }

    /*
    * Set the threshold for automated transfers
    */
    function setThreshold(uint256 _threshold) external {
        require(msg.sender == owner, "Only owner can set threshold");
        threshold = _threshold;
        emit ThresholdUpdated(_threshold);
    }

    /*
    * Change the recipient of the excess funds
    */
    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "Only owner can change owner");
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
    * Receive function to accept direct Ether transfers
    */
    receive() external payable {}

    /*
    * Fallback function to handle any calls to non-existent functions
    */
    fallback() external payable {}
}
