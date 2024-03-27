// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ClaimRegistryUpgradable} from "../src/ClaimRegistryUpgradable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockSBCDepositContract} from "./Mocks.sol";

contract ClaimRegistryUpgradableTest is Test {
    ClaimRegistryUpgradable registry;
    address _depositContractAddress;

    MockSBCDepositContract mockDeposit;

    address val1 = address(1);
    address val2 = address(2);
    address val3 = address(3);

    function setUp() public {
        mockDeposit = new MockSBCDepositContract();
        _depositContractAddress = address(mockDeposit);

        ClaimRegistryUpgradable impl = new ClaimRegistryUpgradable();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        registry = ClaimRegistryUpgradable(address(proxy));
        registry.initialize(_depositContractAddress);

        assertEq(address(registry.depositContract()), address(_depositContractAddress));
    }

    function test_Register() public {
        uint256 timeThreshold = 1 hours;
        uint256 amountThreshold = 1 ether;

        // Simulate successful registration
        vm.prank(val1);
        registry.register(val1, timeThreshold, amountThreshold);

        // Check if the validator is registered
        (, uint256 registeredTimeThreshold, uint256 registeredAmountThreshold,) = registry.configs(val1);
        assertEq(registeredTimeThreshold, timeThreshold);
        assertEq(registeredAmountThreshold, amountThreshold);
    }

    function testFail_RegisterInvalidThresholds() public {
        // Attempt registration with zero thresholds (should fail)
        registry.register(val1, 0, 0);
    }

    function test_UpdateConfig() public {
        uint256 initialTimeThreshold = 1 hours;
        uint256 initialAmountThreshold = 1 ether;
        uint256 newTimeThreshold = 2 hours;
        uint256 newAmountThreshold = 2 ether;

        // Register a validator
        vm.prank(val1);
        registry.register(val1, initialTimeThreshold, initialAmountThreshold);

        // Update the validator's configuration
        vm.prank(val1);
        registry.updateConfig(val1, newTimeThreshold, newAmountThreshold);

        // Check if the configuration is updated
        (, uint256 updatedTimeThreshold, uint256 updatedAmountThreshold,) = registry.configs(val1);
        assertEq(updatedTimeThreshold, newTimeThreshold);
        assertEq(updatedAmountThreshold, newAmountThreshold);
    }

    function testFail_UpdateConfigInvalidUser() public {
        // Attempt to update configuration as a non-registered user (should fail)
        registry.updateConfig(val2, 1 hours, 1 ether);
    }

    // Tests nonZeroParams modifier
    function testFail_UpdateConfigZeroParams() public {
        registry.updateConfig(val2, 0, 0);
    }

    // Tests configActive modifier
    function testFail_UpdateConfigInactiveConfig() public {
        registry.updateConfig(address(123456789), 1, 1);
    }

    function test_Unregister() public {
        uint256 timeThreshold = 1 hours;
        uint256 amountThreshold = 1 ether;

        // Register and then unregister a validator
        vm.prank(val1);
        registry.register(val1, timeThreshold, amountThreshold);
        vm.prank(val1);
        registry.unregister(val1);

        // Check if the validator is unregistered
        (,,, ClaimRegistryUpgradable.ConfigStatus status) = registry.configs(val1);
        assertEq(uint256(status), uint256(ClaimRegistryUpgradable.ConfigStatus.INACTIVE));
    }

    function test_ClaimBatchGasEstimation() public {
        vm.pauseGasMetering();
        mockDeposit.fund(10000, 1 ether);
        vm.resumeGasMetering();

        uint160 i = 1;
        while (true) {
            vm.pauseGasMetering();
            address[] memory withdrawalAddresses = new address[](i);
            for (uint160 j = 0; j < i; j += 1) {
                withdrawalAddresses[j] = address(j);
            }
            vm.resumeGasMetering();

            uint256 oldGas = gasleft();

            try registry.claimBatch(withdrawalAddresses) {
                uint256 gasUsed = oldGas - gasleft();

                i += 50;
                if (oldGas - gasleft() > 29000000) {
                    console.log("OutOfGas bound is around", i, "addresses");
                    break;
                }
            } catch {
                // Out of gas error caught, log the number
                console.log("Out of Gas hit at address count: ", i - 1);
                break;
            }
        }
    }

    function test_Prev() public {
        vm.pauseGasMetering();
        mockDeposit.fund(3000, 1 ether);
        vm.resumeGasMetering();

        uint160 i = 1500;
        // vm.expectRevert();
        for (uint160 j = 0; j < i; j += 1) {
            try registry.claim(address(j)) {}
            catch {
                console.log("Out of Gas hit at address count: ", j);
                break;
            }
        }
    }
}
