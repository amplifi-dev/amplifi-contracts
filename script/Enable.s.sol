// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Amplifi} from "../src/Amplifi.sol";

import {ScriptTypes} from "./ScriptTypes.sol";

contract EnableScript is Script {
    function run(Amplifi amplifi) public {
        vm.startBroadcast(0x4a5c98C184dA163cFffa7F1296c913135565ad3f);
        amplifi.setTradingEnabled(true);
        vm.stopBroadcast();
    }
}
