// 部署 Bank 合约并开源
// forge script scripts/DeployAutoDeposit.s.sol:DeployAutoDepositScript --rpc-url $TESTNET_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY --private-key $USER_PRIVATE_KEY
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "@src/AutoDeposit/TokenBank.sol";

contract DeployAutoDepositScript is Script {
    Bank bank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        bank = new Bank(0.001 ether);
        console.log("Bank deployed at", address(bank));
        vm.stopBroadcast();
    }
}
