// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";


contract ScratchPadScript is Script {
    function run() public {
        address current;
        assembly {
            current := address()
        }

        console.log(current);
    }
}
