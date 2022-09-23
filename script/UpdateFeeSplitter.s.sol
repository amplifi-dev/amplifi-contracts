// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";

import {FeeSplitter} from "../src/FeeSplitter.sol";

contract UpdateFeeSplitterScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);

        uint256 size = 2;

        address[] memory recipients = new address[](size);
        recipients[0] = 0xc766B8c9741BC804FCc378FdE75560229CA3AB1E; // ops
        recipients[1] = 0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17; // devs

        uint16[] memory shares = new uint16[](size);
        shares[0] = 4;
        shares[1] = 1;

        FeeSplitter feeSplitter = FeeSplitter(payable(0x58c5a97c717cA3A7969F82D670A9b9FF16545C6F));
        feeSplitter.setRecipients(recipients, shares);

        feeSplitter = FeeSplitter(payable(0xcbA2712e9Ef4E47690BB73ddF10af1Dc26080131));
        feeSplitter.setRecipients(recipients, shares);

        vm.stopBroadcast();
    }
}
