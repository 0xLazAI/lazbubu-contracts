pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DataAnchorToken} from "../src/dat/DataAnchorToken.sol";
import {DataRegistry} from "../src/dataRegistry/DataRegistry.sol";
import {VerifiedComputing} from "../src/verifiedComputing/VerifiedComputing.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract WorkflowTest is Test {
    Deploy public deployer;

    function setUp() public {
        deployer = new Deploy();
        deployer.run();
    }

    function test_verifiedComputingInitParams() public view {
        VerifiedComputing vc = VerifiedComputing(address(deployer.vcProxy()));
        assertTrue(vc.hasRole(vc.DEFAULT_ADMIN_ROLE(), deployer.admin()));
    }

    function test_dataRegistryInitParams() public view {
        DataRegistry registry = DataRegistry(address(deployer.registryProxy()));
        assertTrue(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), deployer.admin()));
        assertEq(registry.publicKey(), deployer.publicKey());
        assertEq(registry.version(), 1);
    }
}
