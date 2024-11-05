// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  使用Slot模式读取和修改Owner
  确定 owner solt 位置 —> 通过汇编去修改 owner
*/
contract MyWallet { 
    string public name;
    mapping (address => bool) private approved;
    address private owner; // 将 owner 改为 private

    modifier auth {
        require(msg.sender == getOwner(), "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        setOwner(msg.sender);
    } 

    /*
     转移 owner 地址
    */
    function transferOwnership(address _newOwner) external auth {
        require(_newOwner != address(0), "New owner is the zero address");
        require(getOwner() != _newOwner, "New owner is the same as the old owner");
        setOwner(_newOwner);
    }

    // 内联汇编用于获取 owner 地址
    function getOwner() public view returns (address _owner) {
        assembly {
            _owner := sload(owner.slot)
        }
    }

    // 内联汇编用于设置 owner 地址
    function setOwner(address _newOwner) public {
        assembly {
            sstore(owner.slot, _newOwner)
        }
    }
}
