pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DataAnchorToken} from "../../dat/DataAnchorToken.sol";
import {IVerifiedComputing} from "../../verifiedComputing/interfaces/IVerifiedComputing.sol";

interface IDataRegistry {
    struct ProofData {
        uint256 id;
        string fileUrl;
        string proofUrl;
    }

    struct Proof {
        bytes signature;
        ProofData data;
    }

    struct Permission {
        address account;
        string key;
    }

    struct File {
        uint256 id;
        address ownerAddress;
        string url;
        uint256 timestamp;
        uint256 proofIndex;
        uint256 proofsCount;
        uint256 rewardAmount;
        mapping(uint256 proofId => Proof proof) proofs;
        mapping(address account => string key) permissions;
    }

    struct FileResponse {
        uint256 id;
        address ownerAddress;
        string url;
        uint256 proofIndex;
        uint256 rewardAmount;
    }

    function name() external view returns (string memory);
    function version() external pure returns (uint256);
    function token() external view returns (DataAnchorToken);
    function verifiedComputing() external view returns (IVerifiedComputing);
    function updateVerifiedComputing(address newVerifiedComputing) external;

    function pause() external;
    function unpause() external;

    // Public key operations

    function publicKey() external view returns (string memory);
    function updatePublicKey(string calldata newPublicKey) external;

    // Privacy data and file operations

    function addFile(string memory url) external returns (uint256);
    function addFileWithPermissions(string memory url, address ownerAddress, Permission[] memory permissions)
        external
        returns (uint256);
    function addPermissionForFile(uint256 fileId, address account, string memory key) external;

    // File view functions

    function getFile(uint256 fileId) external view returns (FileResponse memory);
    function getFileIdByUrl(string memory url) external view returns (uint256);
    function getFilePermission(uint256 fileId, address account) external view returns (string memory);
    function getFileProof(uint256 fileId, uint256 index) external view returns (Proof memory);
    function filesCount() external view returns (uint256);

    // Proof operations

    function addProof(uint256 fileId, Proof memory proof) external;

    // Request reward and mint token.

    function requestReward(uint256 fileId, uint256 proofIndex) external;
}
