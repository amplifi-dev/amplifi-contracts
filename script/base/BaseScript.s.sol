// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Amplifi, AmplifiNode, IUniswapV2Router02} from "../../src/Amplifi.sol";
import {gAMP} from "../../src/gAMP.sol";

abstract contract BaseScript is Script {
    address constant deployer = 0x4a5c98C184dA163cFffa7F1296c913135565ad3f;
    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Router02 constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address internal owner;

    Amplifi internal amplifi;
    AmplifiNode internal amplifiNode;
    gAMP internal gamp;

    function setUp() public virtual returns (BaseScript) {
        amplifi = Amplifi(payable(vm.envAddress("AMPLIFI")));
        amplifiNode = amplifi.amplifiNode();
        gamp = gAMP(payable(vm.envAddress("GAMP")));

        (owner, ) = deriveRememberKey(vm.envString("SEED"), 0);

        return this;
    }

    function run(Amplifi _amplifi) public {
        amplifi = _amplifi;
        amplifiNode = _amplifi.amplifiNode();

        (bool success, ) = address(this).call(abi.encodeWithSignature("run()"));
        require(success, "Could not run(Amplifi) with Amplifi override");
    }

    function run(Amplifi _amplifi, gAMP _gamp) public {
        amplifi = _amplifi;
        amplifiNode = _amplifi.amplifiNode();
        gamp = _gamp;

        (bool success, ) = address(this).call(abi.encodeWithSignature("run()"));
        require(success, "Could not run(Amplifi) with Amplifi override");
    }
}
