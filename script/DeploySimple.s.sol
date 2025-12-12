pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleLazbubu} from "../src/dat/SimpleLazbubu.sol";
import {LazbubuProxy} from "../src/dat/LazbubuProxy.sol";
import {PermitVerifier} from "../src/dat/PermitVerifier.sol";

contract DeploySimple is Script {
    SimpleLazbubu public token;
    LazbubuProxy public tokenProxy;
    PermitVerifier public permitVerifier;
    address public admin;

    function run() public {
        vm.startBroadcast();
        admin = tx.origin;
        console.log("admin address", admin);
        permitVerifier = new PermitVerifier();
        token = new SimpleLazbubu();
        bytes memory tokenInitData = abi.encodeWithSelector(SimpleLazbubu.initialize.selector, admin, "https://lazai.com/token/{id}.json", address(permitVerifier));
        tokenProxy = new LazbubuProxy(address(token), tokenInitData);
        token = SimpleLazbubu(address(tokenProxy));
        permitVerifier.setServiceTo(address(token));
        permitVerifier.setSigner(admin);
        permitVerifier.setAdmin(admin);
        console.log("token proxy address", address(tokenProxy));
        console.log("permit verifier address", address(permitVerifier));
        vm.stopBroadcast();
    }
}
