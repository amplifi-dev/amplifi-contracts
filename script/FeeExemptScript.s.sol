// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";

contract FeeExemptScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);
        address erc20StakingPoolSingle = 0x71c372ea5B3D3e64a9225F76fa2cC26c2B68024b;
        address erc20StakingPoolLiq = 0xCDCF09B9E24638A1B449358aA4bFA715670603D9;
        amplifi.setIsFeeExempt(erc20StakingPoolSingle, true);
        amplifi.setIsFeeExempt(erc20StakingPoolLiq, true);
        vm.stopBroadcast();
    }
}
