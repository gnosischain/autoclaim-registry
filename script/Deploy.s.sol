// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ClaimRegistryUpgradeable} from "../src/ClaimRegistryUpgradeable.sol";
import {ClaimRegistryProxy} from "../src/ClaimRegistryProxy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployClaimRegistryUpgradeable is Script {
    ClaimRegistryUpgradeable registry;
    address _depositContract = 0x0B98057eA310F4d31F2a452B414647007d1645d9;

    function deploy() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address impl = address(new ClaimRegistryUpgradeable());

        ClaimRegistryProxy proxy =
            new ClaimRegistryProxy(impl, abi.encodeWithSignature("initialize(address,uint256)", _depositContract, 100));

        registry = ClaimRegistryUpgradeable(address(proxy));

        // assertEq(registry.depositContract(), _depositContract);
        // assertEq(registry.batchSizeMax(), 100);
        // assertEq(registry.implementation(), impl);

        vm.stopBroadcast();
    }

    function run() external {
        deploy();
    }
}
