// test/SimpleStorage.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage public simpleStorage;

    function setUp() public {
        simpleStorage = new SimpleStorage();
    }

    function test_SetAndGet() public {
        simpleStorage.set(42);
        uint256 value = simpleStorage.get();
        assertEq(value, 42, "Value should be 42");
    }
}
