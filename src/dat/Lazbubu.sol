// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "./DataAnchoringToken.sol";
import "./utils.sol";

contract Lazbubu is UUPSUpgradeable, DataAnchoringToken {
    bytes32 public constant PERMIT_SIGNER_ROLE = keccak256("PERMIT_SIGNER_ROLE");
    uint8 public constant PERMIT_TYPE_ADVENTURE = 1;
    uint8 public constant PERMIT_TYPE_CREATE_MEMORY = 2;
    uint8 public constant PERMIT_TYPE_SET_LEVEL = 3;
    string public constant name = "Lazbubu";
    string public constant symbol = "LAZBUBU";

    event AdventureCreated(uint256 indexed tokenId, address indexed user, uint8 adventureType, uint256 contentHash);
    event MemoryCreated(uint256 indexed tokenId, uint256 indexed id, address indexed user, uint256 contentHash);
    event MemoryDeleted(uint256 indexed tokenId, uint256 indexed id, address indexed user);
    event LevelSet(uint256 indexed tokenId, address indexed user, uint8 level, bool mature);
    event MessageQuotaClaimed(uint256 indexed tokenId, address indexed user);

    mapping(uint256 => LazbubuState) public states;
    mapping(uint256 => uint128) public nextPermitNonce;
    mapping(uint256 => address) public ownerOf;

    error NotTokenOwner();
    error TokenAlreadyMinted();
    error NonMatureTokenCannotBeTransferred();
    error MessageQuotaAlreadyClaimed();
    error InvalidPermitType();
    error PermitExpired();
    error InvalidDataHash();
    error InvalidNonce();
    error InvalidAmount();
    error TokenAlreadyMature();
    error InvalidPermitSignature();

    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf[tokenId] != _msgSender()) {
            revert NotTokenOwner();
        }
        _;
    }

    modifier onlyPermit(uint256 tokenId, uint8 permitType, bytes memory params, Permit memory permit) {
        _verifyAndInvalidatePermit(permitType, tokenId, params, permit);
        _;
    }

    function initialize(address admin_, string memory uri_) public initializer {
        _DataAnchoringToken_init(admin_, uri_);
        _grantRole(PERMIT_SIGNER_ROLE, admin_);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
    }

    function adventure(uint256 tokenId, uint8 adventureType, uint256 contentHash, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_ADVENTURE, abi.encodePacked(tokenId, adventureType, contentHash), permit) {
        address user = ownerOf[tokenId];
        states[tokenId].adventures.push(Adventure({
            user: user,
            adventureType: adventureType,
            contentHash: contentHash,
            timestamp: uint32(block.timestamp)
        }));
        states[tokenId].adventureCount++;
        emit AdventureCreated(tokenId, user, adventureType, contentHash);
    }

    function createMemory(uint256 tokenId, uint256 contentHash, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_CREATE_MEMORY, abi.encodePacked(tokenId, contentHash), permit) {
        address user = ownerOf[tokenId];
        uint256 id= uint256(keccak256(abi.encodePacked(tokenId, contentHash, uint32(block.timestamp))));
        states[tokenId].memories[id] = Memory({
            contentHash: contentHash,
            timestamp: uint32(block.timestamp)
        });
        emit MemoryCreated(tokenId, id, user, contentHash);
    }

    function deleteMemory(uint256 tokenId, uint256 id) public {
        address user = ownerOf[tokenId];
        delete states[tokenId].memories[id];
        emit MemoryDeleted(tokenId, id, user);
    }

    function setLevel(uint256 tokenId, uint8 level, bool mature, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_SET_LEVEL, abi.encodePacked(tokenId, level, mature), permit) {
        LazbubuState storage state = states[tokenId];
        if (state.maturity != 0) {
            revert TokenAlreadyMature();
        }
        address user = ownerOf[tokenId];
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

        emit MessageQuotaClaimed(tokenId, ownerOf[tokenId]);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual override {
        super._update(from, to, ids, values);
        for (uint256 i = 0; i < ids.length; i++) {
            if (values[i] != 1) {
                revert InvalidAmount();
            }
            uint256 tokenId = ids[i];
            if (from == address(0)) {
                if (ownerOf[tokenId] != address(0)) {
                    revert TokenAlreadyMinted();
                }
                states[tokenId].birthday = uint32(block.timestamp);
            } else {
                if (states[tokenId].maturity == 0) {
                    revert NonMatureTokenCannotBeTransferred();
                }
            }
            ownerOf[tokenId] = to;
        }
    }

    function _verifyAndInvalidatePermit(
        uint8 permitType,
        uint256 tokenId,
        bytes memory params,
        Permit memory permit
    ) private {
        if (permit.permitType != permitType) {
            revert InvalidPermitType();
        }
        if (permit.expire != 0 && permit.expire <= block.timestamp) {
            revert PermitExpired();
        }
        if (permit.dataHash != uint256(keccak256(params))) {
            revert InvalidDataHash();
        }
        if (nextPermitNonce[tokenId] != permit.nonce) {
            revert InvalidNonce();
        }
        if (!hasRole(PERMIT_SIGNER_ROLE, LazbubuUtils.getSigner(permit))) {
            revert InvalidPermitSignature();
        }
        nextPermitNonce[tokenId]++;
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
    uint32 adventureCount;
    Adventure[] adventures;
    mapping(uint256 => Memory) memories;
    uint32 lastTimeMessageQuotaClaimed;
    uint32 firstTimeMessageQuotaClaimed;
}
