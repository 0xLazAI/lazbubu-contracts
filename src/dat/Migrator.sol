// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ILazbubu {
    function migrateToken(bytes memory tokenData) external;
    function migrateAdventure(uint256 tokenId, bytes32 adventureId, address user, uint8 adventureType, uint256 contentHash, uint32 timestamp) external;
    function migrateMemory(uint256 tokenId, uint256 id, address user, uint256 contentHash, uint32 timestamp) external;
}

contract Migrator is Ownable {
    error NotMigrator();

    ILazbubu public lazbubu;
    mapping(address => bool) public migrators;

    constructor(address owner, address lazbubuContract_) Ownable(owner) {
        lazbubu = ILazbubu(lazbubuContract_);
        addMigrator(owner);
    }

    modifier onlyMigrator() {
        if (!migrators[msg.sender]) {
            revert NotMigrator();
        }
        _;
    }

    event TokenMigrated(uint256 indexed tokenId, address indexed owner, string fileUrl, uint32 birthday);
    event AdventureMigrated(uint256 indexed tokenId, bytes32 indexed adventureId, address indexed user, uint8 adventureType, uint256 contentHash, uint32 timestamp);
    event MemoryMigrated(uint256 indexed tokenId, uint256 indexed id, address indexed user, uint256 contentHash, uint32 timestamp);

    function addMigrator(address migrator) public onlyOwner {
        migrators[migrator] = true;
    }

    function removeMigrator(address migrator) public onlyOwner {
        migrators[migrator] = false;
    }

    function migrateTokens(bytes[] memory tokenDataList) public onlyMigrator {
        for (uint256 i = 0; i < tokenDataList.length; i++) {
            lazbubu.migrateToken(tokenDataList[i]);
        }
    }

    function migrateAdventures(bytes[] memory adventureData) public onlyMigrator {
        for (uint256 i = 0; i < adventureData.length; i++) {
            (uint256 tokenId, bytes32 adventureId, address user, uint8 adventureType, uint256 contentHash, uint32 timestamp) = abi.decode(adventureData[i], (uint256, bytes32, address, uint8, uint256, uint32));
            lazbubu.migrateAdventure(tokenId, adventureId, user, adventureType, contentHash, timestamp);
        }
    }

    function migrateMemories(bytes[] memory memoryData) public onlyMigrator {
        for (uint256 i = 0; i < memoryData.length; i++) {
            (uint256 tokenId, uint256 id, address user, uint256 contentHash, uint32 timestamp) = abi.decode(memoryData[i], (uint256, uint256, address, uint256, uint32));
            lazbubu.migrateMemory(tokenId, id, user, contentHash, timestamp);
        }
    }
}