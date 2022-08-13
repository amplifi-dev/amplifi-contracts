// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Solenv} from "solenv/Solenv.sol";

import {DeployScript} from "./Deploy.s.sol";
import {EnableScript} from "./Enable.s.sol";
import {BuyScript} from "./Buy.s.sol";
import {ScriptTypes} from "./ScriptTypes.sol";

contract LocalScript is Script {
    function run() public {
        Solenv.config();

        DeployScript deployScript = new DeployScript();
        ScriptTypes.Contracts memory contracts = deployScript.run();

        EnableScript enableScript = new EnableScript();
        enableScript.run(contracts.amplifi);

        BuyScript buyScript = new BuyScript();
        buyScript.run(contracts.amplifi);
    }
}
