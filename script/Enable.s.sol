// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";

contract EnableScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);
        amplifi.setTradingEnabled(true);
        vm.stopBroadcast();
    }
}
