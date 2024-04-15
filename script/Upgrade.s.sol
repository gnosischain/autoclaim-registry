// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ClaimRegistryUpgradeable} from "../src/ClaimRegistryUpgradeable.sol";
import {ClaimRegistryProxy} from "../src/ClaimRegistryProxy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Upgrade is Script {
    ClaimRegistryUpgradeable registry;
    address _depositContract = 0x0B98057eA310F4d31F2a452B414647007d1645d9;

    function run() external {
        upgradeNoCall();
    }

    function upgradeNoCall() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ClaimRegistryUpgradeable impl = new ClaimRegistryUpgradeable();
        address newImplAddress = address(impl);

        // ClaimRegistryProxy proxy = ClaimRegistryProxy(proxyAddress);
        registry = ClaimRegistryUpgradeable(address(proxyAddress));

        registry.upgradeToAndCall(newImplAddress, "");

        vm.stopBroadcast();
    }
}
