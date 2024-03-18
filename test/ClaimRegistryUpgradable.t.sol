// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import {ClaimRegistryUpgradable} from "../src/ClaimRegistryUpgradable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ClaimRegistryUpgradableTest is Test {
    ClaimRegistryUpgradable registry;
    address _depositContract = 0x0B98057eA310F4d31F2a452B414647007d1645d9;

    function setUp() public {
        ClaimRegistryUpgradable impl = new ClaimRegistryUpgradable();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        registry = ClaimRegistryUpgradable(address(proxy));
        registry.initialize(_depositContract);

        assertEq(address(registry.depositContract()), address(_depositContract));
    }

    function test_ChangeImpl() public {
        ClaimRegistryUpgradable impl2 = new ClaimRegistryUpgradable();
        registry.upgradeToAndCall(address(impl2), "");
        assertEq(address(registry.depositContract()), address(_depositContract));
    }
}
