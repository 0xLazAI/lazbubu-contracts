// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Lazbubu} from "../src/dat/Lazbubu.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract VerifyUpgrade is Script {
    
    function run() public view {
        console.log("Verify Lazbubu upgrade...");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        console.log("Proxy address:", proxyAddress);
        
        // Get current implementation address - need to read from proxy contract's storage slot
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        address currentImplementation;
        assembly {
            currentImplementation := sload(implementationSlot)
        }
        console.log("Current implementation address:", currentImplementation);
        
        // Get admin address - need to read from proxy contract's storage slot
        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        address admin;
        assembly {
            admin := sload(adminSlot)
        }
        console.log("Admin address:", admin);
        
        // Verify contract is working
        Lazbubu token = Lazbubu(proxyAddress);
        
        // Check URI
        string memory uri = token.uri(0);
        console.log("Token URI:", uri);
        
        // Check role
        bytes32 minterRole = token.MINTER_ROLE();
        console.log("MINTER_ROLE:", vm.toString(minterRole));        
        console.log("Verify completed!");
    }
} 