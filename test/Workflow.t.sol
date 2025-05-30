pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DataAnchorToken} from "../src/dat/DataAnchorToken.sol";
import {DataRegistry} from "../src/dataRegistry/DataRegistry.sol";
import {IDataRegistry} from "../src/dataRegistry/interfaces/IDataRegistry.sol";
import {VerifiedComputing} from "../src/verifiedComputing/VerifiedComputing.sol";
import {IVerifiedComputing} from "../src/verifiedComputing/interfaces/IVerifiedComputing.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract WorkflowTest is Test {
    Deploy public deployer;
    VerifiedComputing vc;
    DataRegistry registry;
    address contributor;
    address node;
    address admin;
    string nodeUrl;

    function setUp() public {
        deployer = new Deploy();
        deployer.run();
        vc = deployer.vc();
        registry = deployer.registry();
        contributor = address(0x112233);
        node = address(0x34d9E02F9bB4E4C8836e38DF4320D4a79106F194);
        admin = deployer.admin();
        nodeUrl = "http://localhost:8866";
    }

    function test_verifiedComputingInitParams() public view {
        assertTrue(vc.hasRole(vc.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_dataRegistry() public {
        assertTrue(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(registry.publicKey(), deployer.publicKey());
        assertEq(registry.version(), 1);
        vm.startPrank(contributor);
        assertEq(registry.addFile("file1"), 1);
        vm.stopPrank();

        vm.startPrank(admin);
        vc.addNode(node, nodeUrl, "node public key");
        vc.updateNodeFee(100);
        vm.stopPrank();

        assertEq(vc.nodeFee(), 100);

        vm.startPrank(contributor);
        vm.deal(contributor, 10 ether);
        vc.requestProof{value: 100}(1);
        uint256[] memory ids = vc.fileJobIds(1);
        uint256 jobId = ids[0];
        IVerifiedComputing.Job memory job = vc.getJob(jobId);
        IVerifiedComputing.NodeInfo memory nodeInfo = vc.getNode(job.nodeAddress);
        assertEq(nodeInfo.publicKey, "node public key");
        vm.stopPrank();
        // For privacy data proof
        vm.startPrank(node);
        IDataRegistry.ProofData memory data = IDataRegistry.ProofData({id: 1, fileUrl: "", proofUrl: ""});
        // address 0x34d9E02F9bB4E4C8836e38DF4320D4a79106F194 signature
        bytes memory signature =
            hex"779fa9b7dd09af4941e4627e8dd20d4dea9bec04e22d4b39773b1c966fda92e1517c62a3931e8d6676fb73d1f1bff7142e75beb70796521980e36cc9b87967051c";
        // Finish the Job
        vc.completeJob(jobId);
        vc.claim();
        // Add proof to the data registry
        registry.addProof(1, IDataRegistry.Proof({signature: signature, data: data}));
        vm.stopPrank();

        vm.startPrank(contributor);
        registry.requestReward(1, 1);
        vm.stopPrank();
    }

    function test_DataAnchorToken() public {
        DataAnchorToken token = deployer.token();
        address registryAddr = address(deployer.registry());
        vm.startPrank(registryAddr);
        assertTrue(token.hasRole(token.MINTER_ROLE(), registryAddr));
        address receiver = address(0x112233);
        uint256 mintAmount = 1;
        string memory tokenURI = "https://ipfs.file.url";
        uint256 initialCounter = token.currentTokenId();
        assertEq(initialCounter, 0, "Initial counter should be 0");
        token.mint(receiver, mintAmount, tokenURI, false);
        vm.stopPrank();
        uint256 newCounter = token.currentTokenId();
        assertEq(newCounter, initialCounter + 1, "Counter should increment");
        assertEq(token.balanceOf(receiver, newCounter), mintAmount, "Balance mismatch");
        assertEq(token.uri(newCounter), tokenURI, "Token URI mismatch");
    }
}
