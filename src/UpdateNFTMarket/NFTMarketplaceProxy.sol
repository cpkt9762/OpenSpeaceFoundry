// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract NFTMarketplaceProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,           // Implementation contract
        address admin_,           // Admin address (e.g., TimeLock)
        bytes memory _data        // Initialization data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {}
}