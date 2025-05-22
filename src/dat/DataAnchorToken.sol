pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DataAnchorToken is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Token ID => metadata URI
    mapping(uint256 => string) private _tokenURIs;

    uint256 private _tokenIdCounter;

    constructor(address admin_) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(MINTER_ROLE, admin_);
    }

    function mint(address to, uint256 amount, string memory tokenURI_) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = ++_tokenIdCounter;
        _mint(to, tokenId, amount, "");
        _setTokenURI(tokenId, tokenURI_);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "DataAnchorToken: non-existent token");
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        require(_exists(tokenId), "DataAnchorToken: non-existent token");
        _tokenURIs[tokenId] = tokenURI_;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return bytes(_tokenURIs[tokenId]).length > 0;
    }

    function batchMint(address to, uint256[] memory ids, uint256[] memory amounts, string[] memory tokenURIs)
        public
        onlyRole(MINTER_ROLE)
    {
        require(ids.length == amounts.length, "DataAnchorToken: arrays length mismatch");
        require(ids.length == tokenURIs.length, "DataAnchorToken: arrays length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            _mint(to, tokenId, amounts[i], "");
            _setTokenURI(tokenId, tokenURIs[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}
