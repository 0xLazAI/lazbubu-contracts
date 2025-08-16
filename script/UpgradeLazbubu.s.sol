// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Lazbubu} from "../src/dat/Lazbubu.sol";

contract UpgradeLazbubu is Script {
    
    function run() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        console.log("Start upgrade Lazbubu contract...");
        console.log("Proxy address:", proxyAddress);
        
        vm.startBroadcast();
        Lazbubu newImplementation = new Lazbubu();
        console.log("New implementation address:", address(newImplementation));
        
        Lazbubu(proxyAddress).upgradeToAndCall(address(newImplementation), "");
        console.log("Upgrade completed!");
        vm.stopBroadcast();
    }
} 