// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./DataAnchoringToken.sol";


contract Lazbubu is DataAnchoringToken {
    bytes32 constant PERMIT_SIGNER_ROLE = keccak256("PERMIT_SIGNER_ROLE");
    uint8 constant PERMIT_TYPE_ADVENTURE = 1;
    uint8 constant PERMIT_TYPE_CREATE_MEMORY = 2;
    uint8 constant PERMIT_TYPE_MATURITY = 3;

    event AdventureCreated(uint256 indexed tokenId, address indexed user, uint8 adventureType, uint256 contentHash);
    event MemoryCreated(uint256 indexed tokenId, address indexed user, uint256 contentHash);
    event MaturityReached(uint256 indexed tokenId, address indexed user);

    mapping(uint256 => LazbubuState) public states;
    mapping(address => uint128) public nextPermitNonce;
    mapping(uint256 => address) public ownerOf;

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf[tokenId] == _msgSender(), "Lazbubu: not token owner");
        _;
    }

    modifier onlyPermit(uint8 permitType, bytes memory params, Permit memory permit) {
        _verifyAndInvalidatePermit(permitType, params, permit);
        _;
    }

    function initialize(address admin_, string memory uri_) public initializer {
        _DataAnchoringToken_init(admin_, uri_);
    }

    function adventure(uint256 tokenId, uint8 adventureType, uint256 contentHash, Permit memory permit) public onlyPermit(PERMIT_TYPE_ADVENTURE, abi.encodePacked(tokenId, adventureType, contentHash), permit) {
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

    function createMemory(uint256 tokenId, uint256 contentHash, Permit memory permit) public onlyPermit(PERMIT_TYPE_CREATE_MEMORY, abi.encodePacked(tokenId, contentHash), permit) {
        uint32 timestamp = uint32(block.timestamp);
        address user = ownerOf[tokenId];
        states[tokenId].memories.push(Memory({
            contentHash: contentHash,
            timestamp: timestamp
        }));
        emit MemoryCreated(tokenId, user, contentHash);
    }

    function mature(uint256 tokenId, Permit memory permit) public onlyPermit(PERMIT_TYPE_MATURITY, abi.encodePacked(tokenId), permit) {
        address user = ownerOf[tokenId];
        states[tokenId].maturity = uint32(block.timestamp);
        emit MaturityReached(tokenId, user);
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
            }
            ownerOf[ids[i]] = to;
        }
    }

    function _verifyAndInvalidatePermit(
        uint8 permitType,
        bytes memory params,
        Permit memory permit
    ) private {
        require(permit.permitType == permitType, "Lazbubu: invalid permit type");
        require(
            permit.expire == 0 || permit.expire > block.timestamp,
           "Lazbubu: permit expired"
        );
        require(permit.dataHash == uint256(keccak256(params)), "Lazbubu: invalid data hash");
        require(nextPermitNonce[_msgSender()] == permit.nonce, "Lazbubu: invalid nonce");
        require(hasRole(PERMIT_SIGNER_ROLE, _getSigner(permit)), "Lazbubu: invalid permit signature");
        nextPermitNonce[_msgSender()]++;
    }

    function _getSigner(
        Permit memory permit
    ) private pure returns (address) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                permit.permitType,
                permit.nonce,
                permit.dataHash,
                permit.expire
            )
        );
        return recoverSigner(messageHash, permit.sig);
    }

    function recoverSigner(bytes32 _messageHash, bytes memory sig) private pure returns (address) {
        require(sig.length == 65, "invalid signature length");

        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );

        return ecrecover(ethSignedMessageHash, v, r, s);
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
    uint32 maturity;
    uint32 adventureCount;
    Adventure[] adventures;
    Memory[] memories;
}

struct Permit {
    uint8 permitType;
    uint128 nonce;
    uint dataHash;
    uint expire;
    bytes sig;
}