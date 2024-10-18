// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/*
扩展 ERC20 合约 ，添加一个有hook 功能的转账函数，
如函数名为：transferWithCallback ，
在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。
*/
// Token 接收接口，合约地址需要实现

interface ITokenReceiver {
    function tokensReceived(address sender, uint256 amount) external;
}

contract ERC20WithCallback is IERC20 {
    string public name = "BaseERC20";
    string public symbol = "BERC20";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * (10 ** uint256(decimals));

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // write your code here
        return allowances[_owner][_spender];
    }

    // 检查地址是否是合约地址
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // 带有回调功能的转账函数
    function transferWithCallback(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);

        // 如果目标地址是合约地址，则调用 tokensReceived
        address receiver = recipient;
        if (isContract(receiver)) {
            try ITokenReceiver(receiver).tokensReceived(msg.sender, amount) {
                // 回调成功
            } catch {
                // 回调失败，但我们不回滚交易
            }
        }
        return true;
    }

    // 内部函数执行 token 转账
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "Transfer to the zero address");
        require(balances[sender] >= amount, "Insufficient balance");

        balances[sender] -= amount;
        balances[recipient] += amount;
    }

    // 检查地址时
}
