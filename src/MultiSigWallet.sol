// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
contract SimpleMultiSigWallet {

    /*
     *  Events
     */
    event ProposalSubmitted(uint indexed proposalId, address indexed destination, uint value);
    event ProposalConfirmed(uint indexed proposalId, address indexed owner);
    event ProposalExecuted(uint indexed proposalId);
    event Deposit(address indexed sender, uint value);

    /*
     *  Structs
     */
    struct Proposal {
        address destination;
        uint value;
        bytes data;
        bool executed;
        uint confirmations;
    }

    /*
     *  Storage
     */
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;
    Proposal[] public proposals;
    mapping(uint => mapping(address => bool)) public confirmations;

    /*
     *  Modifiers
     */
    //只有多签持有者可以操作
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    //提案存在
    modifier proposalExists(uint proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        _;
    }
    //提案未执行
    modifier notExecuted(uint proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }
    //提案未确认
    modifier notConfirmed(uint proposalId) {
        require(!confirmations[proposalId][msg.sender], "Already confirmed");
        _;
    }
    //owner存在
    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not exist");
        _;
    }

    //合约构造函数接收所有者列表 _owners 和所需的最少签名数 _required，并在部署时进行初始化
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            require(!isOwner[_owners[i]], "Owner not unique");

            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }

        required = _required;
    }

    /*
     *  Public functions
     */
    /// @dev Allows to deposit ether to the contract.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    // 允许任何所有者提交一个提案，包含目标地址、转账金额和数据。 
    function submitProposal(address destination, uint value, bytes memory data)
        public
       ownerExists(msg.sender)
     returns (uint proposalId)
    {
        proposals.push(Proposal({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            confirmations: 0
        }));
        proposalId = proposals.length - 1; 
        emit ProposalSubmitted(proposalId, destination, value);
        return proposalId; 
    } 

    // 允许其他所有者对未执行的提案进行确认，并且记录确认数。 
    function confirmProposal(uint proposalId)
        public
        onlyOwner
        proposalExists(proposalId)
        notExecuted(proposalId)
        notConfirmed(proposalId)
    {
        /*
        每次确认提案时，增加确认数量，然后检查是否达到门槛 
        */  
        confirmations[proposalId][msg.sender] = true;
        proposals[proposalId].confirmations += 1;
        emit ProposalConfirmed(proposalId, msg.sender); 
    }

    // 执行提案 
    function executeProposal(uint proposalId)
        public
        proposalExists(proposalId)
        notExecuted(proposalId)
    {
        Proposal storage proposal = proposals[proposalId]; 
        // 判断合约余额是否足够 
        require(address(this).balance >= proposal.value, "Insufficient funds.");
        // 再次判断是否达到门槛
        require(proposal.confirmations >= required, "Not enough confirmations");
        // 标记为已执行
        proposal.executed = true;
        // 执行交易
        (bool success, ) = proposal.destination.call{value: proposal.value}(proposal.data);
        require(success, "Transaction failed");
        emit ProposalExecuted(proposalId);
    }
    //isExecuted
    function isExecuted(uint proposalId) public view returns (bool) {
        return proposals[proposalId].executed;
    }
    // 获取提案数量
    function getProposalCount() public view returns (uint) {
        return proposals.length;
    }
    // 获取提案信息
    function getProposal(uint proposalId)
        public
        view
        returns (address destination, uint value, bytes memory data, bool executed, uint confirmations)
    {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.destination, proposal.value, proposal.data, proposal.executed, proposal.confirmations);
    }
}
