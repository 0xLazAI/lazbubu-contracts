// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Lazbubu} from "../src/dat/Lazbubu.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";

contract UpgradeLazbubu is Script {
    
    function run() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        console.log("Start upgrade Lazbubu contract...");
        console.log("Proxy address:", proxyAddress);
        
        vm.startBroadcast();
        
        // The caller will be the address from --private-key
        // This address must have DEFAULT_ADMIN_ROLE on the proxy
        address caller = msg.sender;
        console.log("Upgrade caller address:", caller);
        
        // Check if caller has DEFAULT_ADMIN_ROLE before attempting upgrade
        Lazbubu proxy = Lazbubu(proxyAddress);
        bytes32 defaultAdminRole = proxy.DEFAULT_ADMIN_ROLE();
        bool hasAdminRole = proxy.hasRole(defaultAdminRole, caller);
        console.log("Caller has DEFAULT_ADMIN_ROLE:", hasAdminRole);
        
        if (!hasAdminRole) {
            revert("Caller does not have DEFAULT_ADMIN_ROLE. Please ensure the address from --private-key has admin role.");
        }
        
        Lazbubu newImplementation = new Lazbubu();
        console.log("New implementation address:", address(newImplementation));
        
        // Call upgradeToAndCall through the proxy
        // This must be called by an address with DEFAULT_ADMIN_ROLE
        proxy.upgradeToAndCall(address(newImplementation), "");
        console.log("Upgrade completed!");
        vm.stopBroadcast();
    }
} 