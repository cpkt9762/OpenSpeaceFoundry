pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {esRNT} from "../src/esRNT/esRNT.sol";

contract DeployesRNT is Script {
    function run() public {
        vm.startBroadcast();
        esRNT esrnt = new esRNT();
        vm.stopBroadcast();
    }
}