pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DataAnchorToken} from "../src/dat/DataAnchorToken.sol";
import {DataRegistry} from "../src/dataRegistry/DataRegistry.sol";
import {DataRegistryProxy} from "../src/dataRegistry/DataRegistryProxy.sol";
import {VerifiedComputing} from "../src/verifiedComputing/VerifiedComputing.sol";
import {VerifiedComputingProxy} from "../src/verifiedComputing/VerifiedComputingProxy.sol";

contract Deploy is Script {
    DataAnchorToken public token;
    DataRegistry public registry;
    DataRegistryProxy public registryProxy;
    VerifiedComputing public vc;
    VerifiedComputingProxy public vcProxy;
    address public admin;
    string public name;
    string public publicKey;

    function run() public {
        vm.startBroadcast();
        admin = tx.origin;
        console.log("admin address", admin);
        // Deploy token contract
        token = new DataAnchorToken(admin);
        // Deploy verified computing contract
        vc = new VerifiedComputing();
        bytes memory vcInitData = abi.encodeWithSelector(VerifiedComputing.initialize.selector, admin);
        vcProxy = new VerifiedComputingProxy(address(vc), vcInitData);
        // Deploy data registry contract
        registry = new DataRegistry();
        name = "LazAI Data Registry";
        publicKey = "-----BEGIN PUBLIC KEY-----\n"
            "MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAuGlyRV3LMqjPhdTTWA9r\n"
            "CZM0YY4+UjNLqXiqk4uq2L3r3R13eIXdsXsO+Wvj9yfuSjEkXnVILzpf9EJuy9pg\n"
            "svOu0rlamfLIDUZl/ddy33hCG/7o9TQw2Tem97K2o8SG2a84GmMIgm3NRBw1xTmf\n"
            "i1ngyteSs0GSbXFG5yxiDP/xb0WnH4UwQ74D5BsObF6zbFmsJKQbHiu3D79cjAfy\n"
            "Jn9WenY/Mc2foAM0SQVDLoDzEv5uB6t/5vbOk4g/Hbym1FhQgXQ6NMj+f/40atFM\n"
            "2ZQBy990AkDPwZY9/LiE6i6zjpz6OySsGU71TRL6l0rag4YSPsLoFf/KotcT+/Ph\n"
            "QSzhrs4eyVBPSekEWNW42nMWm+DNluNmV4pIrIfoKLJQGIU+ClOFE3cWxJYj26dQ\n"
            "MfMJoo3I1hSaziCzp9VF1VnF67vHFHAYrsU3CXduYfNNN7ddGtMBrTuu6oFDuMIG\n"
            "as2/7FNsuc4HpRvRJjCRb/lYTC2Y5UBubvWZijMsB/L7AgMBAAE=\n" "-----END PUBLIC KEY-----\n" "\n";
        bytes memory registryInitData = abi.encodeWithSelector(
            DataRegistry.initialize.selector,
            DataRegistry.InitParams({
                ownerAddress: admin,
                tokenAddress: address(token),
                verifiedComputingAddress: address(vc),
                name: name,
                // Note: replace real public key string with the RSA algo
                publicKey: publicKey
            })
        );
        registryProxy = new DataRegistryProxy(address(registry), registryInitData);
        console.log();
        token.grantRole(token.MINTER_ROLE(), address(registry));
        vm.stopBroadcast();
    }
}
