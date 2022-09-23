// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseTest} from "./BaseTest.t.sol";

import {Amplifi, AmplifiNode, IERC20, IUniswapV2Router02, Types} from "../../src/Amplifi.sol";

import {DeployScript} from "../../script/Deploy.s.sol";
import {EnableScript} from "../../script/Enable.s.sol";

import {ScriptTypes} from "../../script/ScriptTypes.sol";

contract BaseTestDeployed is BaseTest {
    function setUp() public virtual override {
        super.setUp();
        owner = deployer;

        vm.deal(owner, 1000 ether);

        amplifi = Amplifi(payable(vm.envAddress("AMPLIFI")));
        amplifiNode = amplifi.amplifiNode();
        router = amplifi.router();
        usdc = amplifi.USDC();
        weth = amplifi.WETH();

        testUtil = testUtil.on(vm).with(amplifi);
    }
}
