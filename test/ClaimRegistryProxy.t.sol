// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ClaimRegistryUpgradeable} from "../src/ClaimRegistryUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ClaimRegistryProxyTest is Test {
    address _depositContract = 0x0B98057eA310F4d31F2a452B414647007d1645d9;
    address _implementation;

    ClaimRegistryUpgradeable registry;
    ERC1967Proxy proxy;

    address newImplAddress;

    function setUp() public {
        ClaimRegistryUpgradeable impl = new ClaimRegistryUpgradeable();
        _implementation = address(impl);
        proxy = new ERC1967Proxy(address(impl), "");
        registry = ClaimRegistryUpgradeable(address(proxy));
        registry.initialize(_depositContract, 100);
    }

    function test_GetImplimentation() public {
        assertEq(registry.implementation(), _implementation);
    }

    function test_UpgradeImplementation() public {
        // Upgrade the proxy to the new implementation
        // vm.prank(address(proxy.getAdmin()));
        newImplAddress = address(new ClaimRegistryUpgradeable());
        registry.upgradeToAndCall(newImplAddress, "");

        // Check if the proxy address is updated
        assertEq(registry.implementation(), newImplAddress);
    }

    function testFail_UpgradeImplementationByNonAdmin() public {
        vm.prank(address(0x123)); // Non-admin address
        registry.upgradeToAndCall(newImplAddress, "");
    }

    function testFail_InvalidUpgradeImplementation() public {
        // vm.prank(address(proxy.admin()));
        registry.upgradeToAndCall(address(0), "");
    }
}
