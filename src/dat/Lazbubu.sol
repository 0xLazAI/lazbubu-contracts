// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "./DataAnchoringToken.sol";
import "./utils.sol";

uint8 constant PERMIT_TYPE_ADVENTURE = 1;
uint8 constant PERMIT_TYPE_CREATE_MEMORY = 2;
uint8 constant PERMIT_TYPE_SET_LEVEL = 3;
uint8 constant PERMIT_TYPE_SET_PERSONALITY = 4;

interface IPermitVerifier {
    function verifyAndInvalidatePermit(uint8 permitType, uint256 tokenId, bytes memory params, Permit memory permit) external;
}

contract Lazbubu is UUPSUpgradeable, DataAnchoringToken {
    string public constant name = "Lazbubu";
    string public constant symbol = "LAZBUBU";
    bytes32 public constant MIGRATE_ROLE = keccak256("MIGRATE_ROLE");

    event AdventureCreated(uint256 indexed tokenId, address indexed user, uint8 adventureType, uint256 contentHash);
    event MemoryCreated(uint256 indexed tokenId, uint256 indexed id, address indexed user, uint256 contentHash);
    event MemoryDeleted(uint256 indexed tokenId, uint256 indexed id, address indexed user);
    event LevelSet(uint256 indexed tokenId, address indexed user, uint8 level, bool mature);
    event MessageQuotaClaimed(uint256 indexed tokenId, address indexed user);
    event PersonalitySet(uint256 indexed tokenId, address indexed user, string personality);
    event AdventureMigrated(uint256 indexed tokenId, bytes32 indexed adventureId, address indexed user, uint8 adventureType, uint256 contentHash, uint32 timestamp);
    event MemoryMigrated(uint256 indexed tokenId, uint256 indexed id, address indexed user, uint256 contentHash, uint32 timestamp);
    event TokenMigrated(uint256 indexed tokenId, address indexed owner, string fileUrl, uint32 birthday);

    mapping(uint256 => LazbubuState) public states;
    address public permitVerifier;

    error NotTokenOwner();
    error TokenAlreadyMinted();
    error NonMatureTokenCannotBeTransferred();
    error InvalidAmount();
    error TokenAlreadyMature();
    error TokenIdMismatch();

    modifier onlyTokenOwner(uint256 tokenId) {
        if (states[tokenId].owner != _msgSender()) {
            revert NotTokenOwner();
        }
        _;
    }

    modifier onlyPermit(uint256 tokenId, uint8 permitType, bytes memory params, Permit memory permit) {
        IPermitVerifier(permitVerifier).verifyAndInvalidatePermit(permitType, tokenId, params, permit);
        _;
    }

    function initialize(address admin_, string memory uri_, address permitVerifier_) public initializer {
        _DataAnchoringToken_init(admin_, uri_);
        permitVerifier = permitVerifier_;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
    }

    function adventure(uint256 tokenId, uint8 adventureType, uint256 contentHash, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_ADVENTURE, abi.encodePacked(tokenId, adventureType, contentHash), permit) {
        address user = states[tokenId].owner;
        emit AdventureCreated(tokenId, user, adventureType, contentHash);
    }

    function createMemory(uint256 tokenId, uint256 contentHash, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_CREATE_MEMORY, abi.encodePacked(tokenId, contentHash), permit) {
        address user = states[tokenId].owner;
        uint256 id= uint256(keccak256(abi.encodePacked(tokenId, contentHash, uint32(block.timestamp))));
        emit MemoryCreated(tokenId, id, user, contentHash);
    }

    function deleteMemory(uint256 tokenId, uint256 id) public {
        address user = states[tokenId].owner;
        emit MemoryDeleted(tokenId, id, user);
    }

    function setPersonality(uint256 tokenId, string memory personality, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_SET_PERSONALITY, abi.encodePacked(tokenId, personality), permit) {
        address user = states[tokenId].owner;
        states[tokenId].personality = personality;
        emit PersonalitySet(tokenId, user, personality);
    }

    function setLevel(uint256 tokenId, uint8 level, bool mature, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_SET_LEVEL, abi.encodePacked(tokenId, level, mature), permit) {
        LazbubuState storage state = states[tokenId];
        if (state.maturity != 0) {
            revert TokenAlreadyMature();
        }
        address user = states[tokenId].owner;
        state.level = level;
        state.maturity = mature ? uint32(block.timestamp) : 0;
        emit LevelSet(tokenId, user, level, mature);
    }
    
    function claimMessageQuota(uint256 tokenId) public onlyTokenOwner(tokenId) {
        LazbubuState storage state = states[tokenId];
        if (state.firstTimeMessageQuotaClaimed == 0) {
            state.firstTimeMessageQuotaClaimed = uint32(block.timestamp);
        }

        state.lastTimeMessageQuotaClaimed = uint32(block.timestamp);

        emit MessageQuotaClaimed(tokenId, states[tokenId].owner);
    }

    function migrateToken(bytes memory tokenData) public onlyRole(MIGRATE_ROLE) {
        (uint256 tokenId, address owner, string memory fileUrl, uint32 birthday, uint8 level, uint32 maturity, uint32 lastTimeMessageQuotaClaimed, uint32 firstTimeMessageQuotaClaimed, string memory personality) = abi.decode(tokenData, (uint256, address, string, uint32, uint8, uint32, uint32, uint32, string));
        mint(owner, 1, fileUrl, true);

        LazbubuState storage state = states[tokenId];
        state.birthday = birthday;
        state.level = level;
        state.maturity = maturity;
        state.lastTimeMessageQuotaClaimed = lastTimeMessageQuotaClaimed;
        state.firstTimeMessageQuotaClaimed = firstTimeMessageQuotaClaimed;
        state.personality = personality;
        emit TokenMigrated(tokenId, owner, fileUrl, birthday);
    }

    function migrateAdventure(uint256 tokenId, bytes32 adventureId, address user, uint8 adventureType, uint256 contentHash, uint32 timestamp) public onlyRole(MIGRATE_ROLE) {
        emit AdventureMigrated(tokenId, adventureId, user, adventureType, contentHash, timestamp);
    }

    function migrateMemory(uint256 tokenId, uint256 id, address user, uint256 contentHash, uint32 timestamp) public onlyRole(MIGRATE_ROLE) {
        emit MemoryMigrated(tokenId, id, user, contentHash, timestamp);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual override {
        super._update(from, to, ids, values);
        for (uint256 i = 0; i < ids.length; i++) {
            if (values[i] != 1) {
                revert InvalidAmount();
            }
            uint256 tokenId = ids[i];
            if (from == address(0)) {
                if (states[tokenId].owner != address(0)) {
                    revert TokenAlreadyMinted();
                }
                states[tokenId].birthday = uint32(block.timestamp);
            } else {
                if (states[tokenId].maturity == 0) {
                    revert NonMatureTokenCannotBeTransferred();
                }
            }
            states[tokenId].owner = to;
        }
    }

}

struct Adventure {
    address user;
    uint8 adventureType;
    uint256 contentHash;
    uint32 timestamp;
}

struct Memory {
    uint256 contentHash;
    uint32 timestamp;
}

struct LazbubuState {
    uint32 birthday;
    uint8 level;
    uint32 maturity;
    uint32 adventureCount; // deprecated
    uint32 lastTimeMessageQuotaClaimed;
    uint32 firstTimeMessageQuotaClaimed;
    string personality;
    address owner;
}
