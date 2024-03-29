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
    address _implementation;

    MockSBCDepositContract mockDeposit;

    uint256 public constant BATCH_SIZE_MAX = 100;

    address val1 = address(1);
    address val2 = address(2);
    address val3 = address(3);

    function setUp() public {
        mockDeposit = new MockSBCDepositContract();
        _depositContractAddress = address(mockDeposit);

        ClaimRegistryUpgradable impl = new ClaimRegistryUpgradable();
        _implementation = address(impl);

        ERC1967Proxy proxy = new ERC1967Proxy(_implementation, "");
        registry = ClaimRegistryUpgradable(address(proxy));
        registry.initialize(_depositContractAddress, BATCH_SIZE_MAX);

        assertEq(address(registry.depositContract()), address(_depositContractAddress));
        assertEq(registry.batchSizeMax(), BATCH_SIZE_MAX);

        test_GetImplimentation();
    }

    function test_GetImplimentation() public {
        assertEq(registry.implementation(), _implementation);
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
                if (gasUsed > 29000000) {
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

        uint160 i = 1;
        // vm.expectRevert();
        for (uint160 j = 0; j < i; j += 1) {
            try registry.claim(address(j)) {}
            catch {
                console.log("Out of Gas hit at address count: ", j);
                break;
            }
        }
    }

    function test_Batching() public {
        uint160 accounts = 200;

        vm.broadcast(val1);
        mockDeposit.fund(accounts, 2 ether);

        for (uint160 i = 0; i < accounts; i++) {
            vm.prank(address(i));
            registry.register(address(i), 1 hours, 1 ether);
        }

        _claimWithBatchAssertions(accounts);
    }

    function _claimWithBatchAssertions(uint160 addresses) private {
        if (uint256(addresses) < BATCH_SIZE_MAX) {
            address[] memory claimableAddrs = registry.getClaimableAddresses();
            vm.broadcast(val1);
            registry.claimBatch(claimableAddrs);
            return;
        }
        for (uint160 i = 0; i < addresses / BATCH_SIZE_MAX; i++) {
            address[] memory claimableAddrs = registry.getClaimableAddresses();
            assertEq(claimableAddrs.length, registry.batchSizeMax());
            // assertEq(claimableAddrs[0], address(uint160(i * BATCH_SIZE_MAX)));

            vm.broadcast(val1);
            registry.claimBatch(claimableAddrs);
        }

        if (addresses % BATCH_SIZE_MAX != 0) {
            address[] memory claimableAddrs = registry.getClaimableAddresses();
            assertEq(claimableAddrs.length, addresses % BATCH_SIZE_MAX);

            vm.broadcast(val1);
            registry.claimBatch(claimableAddrs);
        }

        address[] memory claimableAddrsEmpty = registry.getClaimableAddresses();
        assertEq(claimableAddrsEmpty.length, 0);
    }

    function test_TimeThresholdReached() public {
        test_Batching();

        vm.warp(vm.getBlockTimestamp() + 2 hours);

        _claimWithBatchAssertions(200);
    }
}
