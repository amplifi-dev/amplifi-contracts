// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript, console2} from "./base/BaseScript.s.sol";

contract UpdateRatesScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);
        uint256[] memory rates = new uint256[](20);

        for (uint256 i = 0; i < rates.length; i++) {
            rates[i] = 2 * amplifi.amplifiNode().rates(i);
            console2.log(i, rates[i]);
        }

        amplifi.amplifiNode().setRates(rates);
        vm.stopBroadcast();
    }
}
