// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./DataAnchoringToken.sol";
import "./utils.sol";

contract Lazbubu is UUPSUpgradeable, DataAnchoringToken {
    bytes32 public constant PERMIT_SIGNER_ROLE = keccak256("PERMIT_SIGNER_ROLE");
    uint8 public constant PERMIT_TYPE_ADVENTURE = 1;
    uint8 public constant PERMIT_TYPE_CREATE_MEMORY = 2;
    uint8 public constant PERMIT_TYPE_SET_LEVEL = 3;

    event AdventureCreated(uint256 indexed tokenId, address indexed user, uint8 adventureType, uint256 contentHash);
    event MemoryCreated(uint256 indexed tokenId, address indexed user, uint256 contentHash);
    event LevelSet(uint256 indexed tokenId, address indexed user, uint8 level, bool mature);
    event MessageQuotaClaimed(uint256 indexed tokenId, address indexed user);

    mapping(uint256 => LazbubuState) public states;
    mapping(uint256 => uint128) public nextPermitNonce;
    mapping(uint256 => address) public ownerOf;

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf[tokenId] == _msgSender(), "Lazbubu: not token owner");
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
        // do nothing
    }

    function adventure(uint256 tokenId, uint8 adventureType, uint256 contentHash, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_ADVENTURE, abi.encodePacked(tokenId, adventureType, contentHash), permit) {
        uint32 timestamp = uint32(block.timestamp);
        address user = ownerOf[tokenId];
        states[tokenId].adventures.push(Adventure({
            user: user,
            adventureType: adventureType,
            contentHash: contentHash,
            timestamp: timestamp
        }));
        states[tokenId].adventureCount++;
        emit AdventureCreated(tokenId, user, adventureType, contentHash);
    }

    function createMemory(uint256 tokenId, uint256 contentHash, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_CREATE_MEMORY, abi.encodePacked(tokenId, contentHash), permit) {
        uint32 timestamp = uint32(block.timestamp);
        address user = ownerOf[tokenId];
        states[tokenId].memories.push(Memory({
            contentHash: contentHash,
            timestamp: timestamp
        }));
        emit MemoryCreated(tokenId, user, contentHash);
    }

    function setLevel(uint256 tokenId, uint8 level, bool mature, Permit memory permit) public onlyPermit(tokenId, PERMIT_TYPE_SET_LEVEL, abi.encodePacked(tokenId, level, mature), permit) {
        LazbubuState storage state = states[tokenId];
        require(state.maturity == 0, "Lazbubu: token already mature");
        address user = ownerOf[tokenId];
        state.level = level;
        state.maturity = mature ? uint32(block.timestamp) : 0;
        emit LevelSet(tokenId, user, level, mature);
    }
    
    function claimMessageQuota(uint256 tokenId) public onlyTokenOwner(tokenId) {
        LazbubuState storage state = states[tokenId];
        if (state.firstTimeMessageQuotaClaimed == 0) {
            state.firstTimeMessageQuotaClaimed = uint32(block.timestamp);
        } else {
            (bool claimed, , , ) = messageQuotaClaimedToday(tokenId);
            require(!claimed, "Lazbubu: message quota already claimed");
        }

        state.lastTimeMessageQuotaClaimed = uint32(block.timestamp);

        emit MessageQuotaClaimed(tokenId, ownerOf[tokenId]);
    }
    
    function messageQuotaClaimedToday(uint256 tokenId) public view returns (bool claimed, uint32 dayStart, uint32 dayEnd, uint32 firstTimeClaimed) {
        LazbubuState memory state = states[tokenId];
        uint32 timestamp = uint32(block.timestamp);
        dayStart = timestamp - (timestamp - state.firstTimeMessageQuotaClaimed) % 1 days;
        dayEnd = dayStart + 1 days;
        claimed = dayStart <= state.lastTimeMessageQuotaClaimed;
        firstTimeClaimed = state.firstTimeMessageQuotaClaimed;
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual override {
        super._update(from, to, ids, values);
        for (uint256 i = 0; i < ids.length; i++) {
            require(values[i] == 1, "Lazbubu: invalid amount");
            if (from == address(0)) {
                // Ensure token hasn't been minted before
                require(ownerOf[ids[i]] == address(0), "Lazbubu: token already minted");
                // birthday is set when minted
                states[ids[i]].birthday = uint32(block.timestamp);
            } else {
                // normal transfer (not allowed for non-mature token)
                require(states[ids[i]].maturity > 0, "Lazbubu: non-mature token cannot be transferred");
            }
            ownerOf[ids[i]] = to;
        }
    }

    function _verifyAndInvalidatePermit(
        uint8 permitType,
        uint256 tokenId,
        bytes memory params,
        Permit memory permit
    ) private {
        require(permit.permitType == permitType, "Lazbubu: invalid permit type");
        require(
            permit.expire == 0 || permit.expire > block.timestamp,
           "Lazbubu: permit expired"
        );
        require(permit.dataHash == uint256(keccak256(params)), "Lazbubu: invalid data hash");
        require(nextPermitNonce[tokenId] == permit.nonce, "Lazbubu: invalid nonce");
        require(hasRole(PERMIT_SIGNER_ROLE, LazbubuUtils.getSigner(permit)), "Lazbubu: invalid permit signature");
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
    Memory[] memories;
    uint32 lastTimeMessageQuotaClaimed;
    uint32 firstTimeMessageQuotaClaimed;
}
