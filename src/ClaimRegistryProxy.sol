// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./ClaimRegistryUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract ClaimRegistryProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _calldata) ERC1967Proxy(_implementation, _calldata) {}
}
