// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";  

 interface IPermit2 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract TokenBank {
    // ERC20 Token 合约地址
    IERC20  public token; 
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // 每个用户的存款记录 
    mapping(address => uint256) public balances;

    // 构造函数，初始化 Token 合约地址
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
       
    }

    // 存款函数，用户将 Token 存入 TokenBank
    function deposit(uint256 amount) public virtual {
        require(amount > 0, "Amount must be greater than 0");

        // 将用户的 Token 转移到合约地址
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // 更新用户的存款记录
        balances[msg.sender] += amount;

        // call deposit event
        emit Deposit(msg.sender, amount);
    }

    // 存款函数，用户将 ETH 存入 TokenBank
    function depositETH() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // 提款函数，用户可以提取他们的存款
    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 更新用户的存款记录
        balances[msg.sender] -= amount;

        // 将 Token 发送回用户
        require(token.transfer(msg.sender, amount), "Token transfer failed");

        // call withdraw event
        emit Withdraw(msg.sender, amount);
    }

    // 查询用户的存款余额
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    // Use the permit function to authorize deposits
    function permitDeposit( 
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external { 
        require(_deadline > block.timestamp, "Deadline must be in the future");
        // Use the permit function to authorize the deposit
        ERC20Permit(address(token)).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        // Execute the transfer operation
        token.transferFrom(msg.sender, address(this), _amount);
        // Update the deposit balance
        balances[msg.sender] += _amount;

        // call deposit event
        emit Deposit(msg.sender, _amount);
    }

   
}

/*继承 TokenBank 编写 TokenBankV2，
支持存入扩展的 ERC20 Token，
用户可以直接调用 transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中。
*/
contract TokenBankV2 is TokenBank {
    address public permit2Contract;
    constructor(address _tokenAddress) TokenBank(_tokenAddress) {
        permit2Contract = _tokenAddress;
    }

    //TokenBankV2 需要实现 tokensReceived 来实现存款记录工作
    function tokensReceived(address sender, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(msg.sender == address(token), "Only callable by token contract");
        balances[sender] += amount;
    }

    function depositWithPermit2(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(permit2Contract != address(0), "Permit2 contract not set");
        require(amount > 0, "Amount must be greater than 0");
        require(deadline > block.timestamp, "Deadline must be in the future");

        // 使用 permit2 进行授权
        IPermit2(permit2Contract).permit(msg.sender, address(this), amount, deadline, v, r, s);
        
        // 转账 token 到合约
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // 更新存款余额
        balances[msg.sender] += amount;
    }
}
