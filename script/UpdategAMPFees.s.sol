// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";

contract UpdategAMPFeesScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);

        gamp.setFees(0.001 ether, 300);

        vm.stopBroadcast();
    }
}
