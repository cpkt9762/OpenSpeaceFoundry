// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
}

contract MyERC20Token is IERC20 {
    string public name = "BaseERC20";
    string public symbol = "BERC20";
    uint8 public decimals = 18;

    uint256 public totalSupply = 100000000 * 10 ** decimals;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowances;

    // event Transfer(address indexed from, address indexed to, uint256 value);
    // event Approval(address indexed owner, address indexed spender, uint256 value);

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
    //erc20 trasnferWithOutPermit
    //实现离线签名 
    function transferWithPermit(Permit calldata permit,uint8 v,bytes32 r,bytes32 s) public returns (bool success) {
        // 1. 验证签名
        // 2. 验证签名是否有效
        // 3. 验证签名是否过期
        // 4. 验证签名是否正确
        // 5. 验证签名是否正确  
        
        
        
    }
}
