pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Lazbubu} from "../src/dat/Lazbubu.sol";
import {LazbubuProxy} from "../src/dat/LazbubuProxy.sol";
import {DataRegistry} from "../src/dataRegistry/DataRegistry.sol";
import {DataRegistryProxy} from "../src/dataRegistry/DataRegistryProxy.sol";
import {VerifiedComputing} from "../src/verifiedComputing/VerifiedComputing.sol";
import {VerifiedComputingProxy} from "../src/verifiedComputing/VerifiedComputingProxy.sol";
import {AIProcess} from "../src/process/AIProcess.sol";
import {AIProcessProxy} from "../src/process/AIProcessProxy.sol";
import {Settlement} from "../src/settlement/Settlement.sol";
import {SettlementProxy} from "../src/settlement/SettlementProxy.sol";
import {IDAO} from "../src/idao/IDAO.sol";
import {IDAOProxy} from "../src/idao/IDAOProxy.sol";
import {PermitVerifier} from "../src/dat/PermitVerifier.sol";
import {Migrator} from "../src/dat/Migrator.sol";

contract Deploy is Script {
    PermitVerifier public permitVerifier;
    Migrator public migrator;
    Lazbubu public token;
    LazbubuProxy public tokenProxy;
    DataRegistry public registry;
    DataRegistryProxy public registryProxy;
    VerifiedComputing public vc;
    VerifiedComputingProxy public vcProxy;
    AIProcess public query;
    AIProcessProxy public queryProxy;
    AIProcess public inference;
    AIProcessProxy public inferenceProxy;
    AIProcess public training;
    AIProcessProxy public trainingProxy;
    Settlement public settlement;
    SettlementProxy public settlementProxy;
    IDAO public idao;
    IDAOProxy public idaoProxy;
    address public admin;
    string public name;
    string public publicKey;

    function run() public {
        vm.startBroadcast();
        admin = tx.origin;
        console.log("admin address", admin);
        // Deploy permit verifier contract

        permitVerifier = new PermitVerifier();
        console.log("permit verifier address", address(permitVerifier));

        // Deploy token contract
        token = new Lazbubu();
        bytes memory tokenInitData = abi.encodeWithSelector(Lazbubu.initialize.selector, admin, "https://lazai.com/token/{id}.json", address(permitVerifier));
        tokenProxy = new LazbubuProxy(address(token), tokenInitData);
        token = Lazbubu(address(tokenProxy));
        console.log("token address", address(token));
        permitVerifier.setServiceTo(address(token));
        permitVerifier.setSigner(admin);
        permitVerifier.setAdmin(admin);
        console.log("permit verifier initialized");

        // Deploy verified computing contract
        vc = new VerifiedComputing();
        bytes memory vcInitData = abi.encodeWithSelector(VerifiedComputing.initialize.selector, admin);
        vcProxy = new VerifiedComputingProxy(address(vc), vcInitData);
        vc = VerifiedComputing(address(vcProxy));
        console.log("verified computing address", address(vc));
        // Deploy data registry contract
        registry = new DataRegistry();
        name = "LazAI Data Registry";
        publicKey = vm.envString("PUBLIC_KEY");
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

        // Deploy migrator contract
        migrator = new Migrator(admin, address(token));
        console.log("migrator address", address(migrator));
        token.grantRole(token.MIGRATE_ROLE(), address(migrator));

        // Deploy query contract
        query = new AIProcess();
        bytes memory queryInitData = abi.encodeWithSelector(AIProcess.initialize.selector, admin, address(0), 3600);
        queryProxy = new AIProcessProxy(address(query), queryInitData);
        query = AIProcess(address(queryProxy));
        console.log("query address", address(query));

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
        bytes memory settlementInitData = abi.encodeWithSelector(
            Settlement.initialize.selector, admin, address(query), address(inference), address(training)
        );
        settlementProxy = new SettlementProxy(address(settlement), settlementInitData);
        settlement = Settlement(address(settlementProxy));
        console.log("settlement address", address(settlement));

        // Update settlement address into the data query, inference and training contracts
        query.updateSettlement(address(settlement));
        inference.updateSettlement(address(settlement));
        training.updateSettlement(address(settlement));

        // Deploy LazAI iDAO
        idao = new IDAO();
        bytes memory idaoInitData = abi.encodeWithSelector(
            IDAO.initialize.selector,
            IDAO.InitParams({
                ownerAddress: admin,
                tokenAddress: address(token),
                verifiedComputingAddress: address(vc),
                settlementAddress: address(settlement),
                name: "LazAI",
                description: "LazAI is a decentralized autonomous organization (DAO) dedicated to building a trustworthy and efficient ecosystem for AI computing and data. Through blockchain technology, we enable decentralized collaboration for AI model training, inference services, and data sharing, allowing participants to contribute, access, and distribute value fairly. Our mission is to break down data silos in AI development, establish a transparent, secure, and incentive-compatible AI community, and promote the inclusive and innovative development of artificial intelligence technology."
            })
        );
        idaoProxy = new IDAOProxy(address(idao), idaoInitData);
        idao = IDAO(address(idaoProxy));
        console.log("idao address", address(idao));

        // Show proxy contract addresses
        console.log("verified computing proxy address", address(vcProxy));
        console.log("data registry proxy address", address(registryProxy));
        console.log("query proxy address", address(queryProxy));
        console.log("inference proxy address", address(inferenceProxy));
        console.log("training proxy address", address(trainingProxy));
        console.log("settlement proxy address", address(settlementProxy));
        console.log("idao proxy address", address(idaoProxy));

        vm.stopBroadcast();
    }
}
