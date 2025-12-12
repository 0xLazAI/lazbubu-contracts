// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleLazbubu} from "../src/dat/SimpleLazbubu.sol";

contract UpgradeLazbubuSimple is Script {
    
    function run() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        console.log("Start upgrade SimpleLazbubu contract...");
        console.log("Proxy address:", proxyAddress);
        
        vm.startBroadcast();
        SimpleLazbubu newImplementation = new SimpleLazbubu();
        console.log("New implementation address:", address(newImplementation));
        
        SimpleLazbubu(proxyAddress).upgradeToAndCall(address(newImplementation), "");
        console.log("Upgrade completed!");
        vm.stopBroadcast();
    }
} 