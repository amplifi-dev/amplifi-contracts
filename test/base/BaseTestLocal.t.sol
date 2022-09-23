// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseTest} from "./BaseTest.t.sol";

import {Amplifi, AmplifiNode, IERC20, IUniswapV2Router02, Types} from "../../src/Amplifi.sol";

import {DeployScript} from "../../script/Deploy.s.sol";
import {EnableScript} from "../../script/Enable.s.sol";

import {ScriptTypes} from "../../script/ScriptTypes.sol";

contract BaseTestLocal is BaseTest {
    function setUp() public virtual override {
        super.setUp();

        uint256 ownerKey = vm.deriveKey(vm.envString("SEED"), 0);
        owner = vm.addr(ownerKey);

        deal(owner, 1000 ether);
        deal(USDC, owner, 150_000e6);

        contracts = DeployScript(address(new DeployScript().setUp())).run();

        amplifi = contracts.amplifi;
        amplifiNode = amplifi.amplifiNode();
        router = amplifi.router();
        usdc = amplifi.USDC();
        weth = amplifi.WETH();

        testUtil = testUtil.on(vm).with(amplifi);
    }

    function runEnableScript() public {
        new EnableScript().setUp().run(amplifi);
    }
}
