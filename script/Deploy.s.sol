pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DataAnchorToken} from "../src/dat/DataAnchorToken.sol";
import {DataRegistry} from "../src/dataRegistry/DataRegistry.sol";
import {DataRegistryProxy} from "../src/dataRegistry/DataRegistryProxy.sol";
import {VerifiedComputing} from "../src/verifiedComputing/VerifiedComputing.sol";
import {VerifiedComputingProxy} from "../src/verifiedComputing/VerifiedComputingProxy.sol";
import {AIProcess} from "../src/process/AIProcess.sol";
import {AIProcessProxy} from "../src/process/AIProcessProxy.sol";
import {Settlement} from "../src/settlement/Settlement.sol";
import {SettlementProxy} from "../src/settlement/SettlementProxy.sol";

contract Deploy is Script {
    DataAnchorToken public token;
    DataRegistry public registry;
    DataRegistryProxy public registryProxy;
    VerifiedComputing public vc;
    VerifiedComputingProxy public vcProxy;
    AIProcess public inference;
    AIProcessProxy public inferenceProxy;
    AIProcess public training;
    AIProcessProxy public trainingProxy;
    Settlement public settlement;
    SettlementProxy public settlementProxy;
    address public admin;
    string public name;
    string public publicKey;

    function run() public {
        vm.startBroadcast();
        admin = tx.origin;
        console.log("admin address", admin);
        // Deploy token contract
        token = new DataAnchorToken(admin);
        console.log("token address", address(token));
        // Deploy verified computing contract
        vc = new VerifiedComputing();
        bytes memory vcInitData = abi.encodeWithSelector(VerifiedComputing.initialize.selector, admin);
        vcProxy = new VerifiedComputingProxy(address(vc), vcInitData);
        vc = VerifiedComputing(address(vcProxy));
        console.log("verified computing address", address(vc));
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
        registry = DataRegistry(address(registryProxy));
        console.log("data registry address", address(registry));
        token.grantRole(token.MINTER_ROLE(), address(registry));

        // Deploy inference contract
        inference = new AIProcess();
        bytes memory inferenceInitData = abi.encodeWithSelector(AIProcess.initialize.selector, admin, address(0), 3600);
        inferenceProxy = new AIProcessProxy(address(inference), inferenceInitData);
        inference = AIProcess(address(inferenceProxy));
        console.log("inference address", address(inference));
        // Deploy training contract
        training = new AIProcess();
        bytes memory trainingInitData = abi.encodeWithSelector(AIProcess.initialize.selector, admin, address(0), 3600);
        trainingProxy = new AIProcessProxy(address(training), trainingInitData);
        training = AIProcess(address(trainingProxy));
        console.log("training address", address(training));
        // Deploy settlement contract
        settlement = new Settlement();
        bytes memory settlementInitData =
            abi.encodeWithSelector(Settlement.initialize.selector, admin, address(inference), address(training));
        settlementProxy = new SettlementProxy(address(settlement), settlementInitData);
        settlement = Settlement(address(settlementProxy));
        console.log("settlement address", address(settlement));

        // Update settlement address into the inference and training contracts
        inference.updateSettlement(address(settlement));
        training.updateSettlement(address(settlement));
        vm.stopBroadcast();
    }
}
