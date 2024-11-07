// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "forge-std/console.sol";

contract MyPermitToken is ERC20, ERC20Permit, Ownable {
    constructor() ERC20("MyPermitToken", "MPT") ERC20Permit("MyPermitToken") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // 初始化铸造 100 万代币
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function getPermitTypehash() public pure returns (bytes32) {
        bytes32 PERMIT_TYPEHASH =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        return PERMIT_TYPEHASH;
    }
}
