// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "lib/permit2/src/Permit2.sol";
import "lib/permit2/src/interfaces/IPermit2.sol";
import "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "forge-std/console.sol"; 

contract TokenBank { 
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // 每个用户的存款记录 
    mapping(IERC20 => mapping(address => uint256)) balances;

    // 构造函数，初始化 Token 合约地址
    constructor() {  
    }

    // 存款函数，用户将 Token 存入 TokenBank
    function deposit(IERC20 token,uint256 amount) public virtual {
        require(amount > 0, "Amount must be greater than 0");

        // 将用户的 Token 转移到合约地址
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // 更新用户的存款记录
        balances[token][msg.sender] += amount;

        // call deposit event
        emit Deposit(msg.sender, amount);
    }

    // 存款函数，用户将 ETH 存入 TokenBank
    function depositETH(IERC20 token) external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[token][msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // 提款函数，用户可以提取他们的存款
    function withdraw(IERC20 token,uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[token][msg.sender] >= amount, "Insufficient balance");

        // 更新用户的存款记录
        balances[token][msg.sender] -= amount;

        // 将 Token 发送回用户
        require(token.transfer(msg.sender, amount), "Token transfer failed");

        // call withdraw event
        emit Withdraw(msg.sender, amount);
    }

    // 查询用户的存款余额
    function getBalance(IERC20 token,address user) public view returns (uint256) {
        return balances[token][user];
    }

    // Use the permit function to authorize deposits
    function permitDeposit( 
        IERC20 token,
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
        balances[token][msg.sender] += _amount;

        // call deposit event
        emit Deposit(msg.sender, _amount);
    }

    function getTokenBalance(IERC20 token, address user) public view returns (uint256) {
        return balances[token][user];
    }
   
}
 
contract TokenBankV2 is TokenBank {
     IPermit2 public  immutable permit2Contract;
    constructor(IPermit2 _permit2Contract) TokenBank() {
        permit2Contract = IPermit2(_permit2Contract);
    }

    //TokenBankV2 需要实现 tokensReceived 来实现存款记录工作
    function tokensReceived(IERC20 token,address sender, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(msg.sender == address(token), "Only callable by token contract");
        balances[token][sender] += amount;
        
    } 

     /**
     * @dev Deposits tokens into the contract using Uniswap's Permit2 signature for authorization.
     * @param token The address of the token to deposit.
     * @param amount The amount of tokens to deposit.
     * @param deadline The expiration time of the permit signature.
     * @param nonce The unique nonce for this permit. 
     * @param signature The signature of the owner.
     */
    function depositWithPermit2(
        IERC20 token,
        uint256 amount,
        uint256 deadline,
        uint256 nonce,
        bytes calldata signature
    ) external { 
        require(amount > 0, "Amount must be greater than 0");
        require(deadline > block.timestamp, "Deadline must be in the future"); 

     
       permit2Contract.permitTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: address(token),
                    amount: amount
                }),
                nonce: nonce,
                deadline: deadline
            }),
            // The transfer recipient and amount.
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: amount
            }),
            msg.sender,
            signature
        );

        balances[token][msg.sender] += amount;

        // Emit a deposit event
        emit DepositWithPermit2(msg.sender, amount);
    }

    event DepositWithPermit2(address indexed from, uint256 amount);
}
