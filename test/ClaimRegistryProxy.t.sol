// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ClaimRegistryUpgradable} from "../src/ClaimRegistryUpgradable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ClaimRegistryProxyTest is Test {
    address _depositContract = 0x0B98057eA310F4d31F2a452B414647007d1645d9;

    ClaimRegistryUpgradable registry;
    ERC1967Proxy proxy;

    address newImplAddress;

    function setUp() public {
        ClaimRegistryUpgradable impl = new ClaimRegistryUpgradable();
        proxy = new ERC1967Proxy(address(impl), "");
        registry = ClaimRegistryUpgradable(address(proxy));
        registry.initialize(_depositContract, 100);
    }

    // function test_UpgradeImplementation() public {
    //     // Upgrade the proxy to the new implementation
    //     // vm.prank(address(proxy.getAdmin()));
    //     newImplAddress = address(new ClaimRegistryUpgradable());
    //     registry.upgradeToAndCall(newImplAddress, "");

    //     // Check if the proxy address is updated
    //     assertEq(registry.getImplementation(), newImplAddress);
    // }

    function testFail_UpgradeImplementationByNonAdmin() public {
        vm.prank(address(0x123)); // Non-admin address
        registry.upgradeToAndCall(newImplAddress, "");
    }

    function testFail_InvalidUpgradeImplementation() public {
        // vm.prank(address(proxy.admin()));
        registry.upgradeToAndCall(address(0), "");
    }
}
