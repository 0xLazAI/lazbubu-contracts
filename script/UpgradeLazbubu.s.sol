// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Lazbubu} from "../src/dat/Lazbubu.sol";
import {LazbubuProxy} from "../src/dat/LazbubuProxy.sol";
import {LazbubuUpgrader} from "../src/dat/LazbubuUpgrader.sol";

contract UpgradeLazbubu is Script {
    
    function run() public {
        vm.startBroadcast();
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        console.log("Start upgrade Lazbubu contract...");
        console.log("Proxy address:", proxyAddress);
        
        // 1. Deploy new implementation contract
        Lazbubu newImplementation = new Lazbubu();
        console.log("New implementation address:", address(newImplementation));
        
        // 2. Deploy upgrader contract (if not deployed)
        LazbubuUpgrader upgrader = new LazbubuUpgrader();
        console.log("Upgrader contract address:", address(upgrader));
        
        // 3. Use upgrader contract to upgrade proxy contract
        upgrader.upgradeProxy(proxyAddress, address(newImplementation));
        
        console.log("Upgrade completed!");
        console.log("New implementation address:", address(newImplementation));
        
        vm.stopBroadcast();
    }
} 