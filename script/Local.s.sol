// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import {BaseScript} from "./base/BaseScript.s.sol";

contract LocalScript is BaseScript {
    function run() public {
        address[] memory path = new address[](3);
        path[0] = weth;
        path[1] = usdc;
        path[2] = address(amplifi);

        vm.startBroadcast(owner);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 100 ether}(
            0,
            path,
            owner,
            block.timestamp + 10 minutes
        );
        vm.stopBroadcast();
    }
}
