// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/esRNT/esRNT.sol";
import "forge-std/console.sol";
contract esRNTTest is Test {
    esRNT tokenContract;
    function setUp() public {
       
    }
   function testReadLocks() public {
     tokenContract = new esRNT();
        // `_locks` array's base slot is 0 in the esRNT contract
        bytes32 baseSlot = keccak256(abi.encodePacked(uint256(0)));

        // Assuming `_locks` array has 11 elements (you can adjust this as needed)
        uint256 numberOfElements = 11;

        for (uint256 i = 0; i < numberOfElements; i++) {
            // Calculate the storage slot for _locks[i]
            bytes32 elementSlot = bytes32(uint256(keccak256(abi.encodePacked(baseSlot))) + i);

            // Read the storage directly using assembly
            (address user, uint64 startTime, uint256 amount) = readLockInfo(elementSlot);
            console.log("--------------------------------");
            console.log("i: ", i);
            console.log("elementSlot: ");
           console.logBytes32(elementSlot);
           console.log("user: ");
           console.logAddress(user);
           console.log("startTime: ");
           console.log(startTime);
           console.log("amount: ");
           console.log(amount); 
        }
    }

    function readLockInfo(bytes32 slot) internal view returns (address user, uint64 startTime, uint256 amount) {
        bytes32 data;
        assembly {
            data := sload(slot)
        }

        // Decode data manually from the storage layout of LockInfo struct
        user = address(uint160(uint256(data >> 96))); // user is 20 bytes
        startTime = uint64(uint256(data >> 32));      // startTime is 8 bytes
        amount = uint256(data & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF); // amount is 32 bytes
    }
}
