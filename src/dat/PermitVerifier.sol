// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "./DataAnchoringToken.sol";
import "./utils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PermitVerifier {
    event PermitInvalidated(uint256 indexed tokenId, uint8 permitType, bytes params, uint128 nonce, uint256 dataHash, uint256 expire, bytes sig);

    address public admin;
    address public serviceTo;
    address public signer;
    mapping(uint256 => uint128) public nextPermitNonce;
    error InvalidPermitType();
    error PermitExpired();
    error InvalidDataHash();
    error InvalidNonce();
    error InvalidPermitSignature();
    error NotAdmin();
    error NotServiceTo();

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    modifier onlyServiceTo() {
        if (msg.sender != serviceTo) {
            revert NotServiceTo();
        }
        _;
    }

    constructor() {
        admin = signer = msg.sender;
    }

    function setAdmin(address admin_) public onlyAdmin {
        admin = admin_;
    }

    function setSigner(address signer_) public onlyAdmin {
        signer = signer_;
    }

    function setServiceTo(address serviceTo_) public onlyAdmin {
        serviceTo = serviceTo_;
    }

    function verifyAndInvalidatePermit(
        uint8 permitType,
        uint256 tokenId,
        bytes memory params,
        Permit memory permit
    ) external onlyServiceTo {
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
        if (signer != LazbubuUtils.getSigner(permit)) {
            revert InvalidPermitSignature();
        }
        nextPermitNonce[tokenId]++;
        emit PermitInvalidated(tokenId, permitType, params, permit.nonce, permit.dataHash, permit.expire, permit.sig);
    }
}
