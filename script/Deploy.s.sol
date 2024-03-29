// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ClaimRegistryUpgradable} from "../src/ClaimRegistryUpgradable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployClaimRegistryUpgradable is Script {
    ClaimRegistryUpgradable registry;
    address _depositContract = 0x0B98057eA310F4d31F2a452B414647007d1645d9;

    function deploy() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ClaimRegistryUpgradable impl = new ClaimRegistryUpgradable();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        registry = ClaimRegistryUpgradable(address(proxy));
        registry.initialize(_depositContract, 100);

        vm.stopBroadcast();
    }

    function run() external {
        deploy();
    }
}
