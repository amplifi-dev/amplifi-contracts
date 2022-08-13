// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Amplifi} from "../src/Amplifi.sol";

import {ScriptTypes} from "./ScriptTypes.sol";

contract BuyScript is Script {
    function run(Amplifi amplifi) public {
        vm.startBroadcast(0x4a5c98C184dA163cFffa7F1296c913135565ad3f);

        address[] memory path = new address[](3);
        address usdc = address(amplifi.USDC());
        address weth = address(amplifi.WETH());
        path[0] = weth;
        path[1] = usdc;
        path[2] = address(amplifi);

        uint256 account2PrivateKey = vm.deriveKey(vm.envString("SEED"), 1);
        address account2 = vm.addr(account2PrivateKey);

        amplifi.router().swapExactETHForTokensSupportingFeeOnTransferTokens{value: 1 ether}(
            0,
            path,
            account2,
            block.timestamp + 10 minutes
        );

        vm.stopBroadcast();
    }
}
