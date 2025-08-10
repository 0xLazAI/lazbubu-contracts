// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LazbubuUpgrader is Ownable {
    constructor() Ownable(msg.sender) {}
    
    event Upgraded(address indexed proxy, address indexed implementation);
    
    function upgradeProxy(address proxy, address newImplementation) external onlyOwner {
        require(proxy != address(0), "Invalid proxy address");
        require(newImplementation != address(0), "Invalid implementation address");
        
        // ERC1967 implementation slot
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        
        // Update the implementation address
        assembly {
            sstore(implementationSlot, newImplementation)
        }
        
        emit Upgraded(proxy, newImplementation);
    }
    
    function getImplementation(address /* proxy */) external view returns (address) {
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        address implementation;
        assembly {
            implementation := sload(implementationSlot)
        }
        return implementation;
    }
} 