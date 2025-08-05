library LazbubuUtils {
    function makeMetadata(string memory name, string memory description, string memory image) public pure returns (string memory) {
        return string(abi.encodePacked(
    "{
	\"name\": \"",
	name,
	"\",
	\"description\": \"",
	description,
	"\",
	\"image\": \"",
	image,
	"\"
    }"
        ));
    }

    function makeDataURI(string memory name, string memory description, string memory image) public pure returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(makeMetadata(name, description, image)))
        ));
    }

    function getSigner(
        Permit memory permit
    ) public pure returns (address) {
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