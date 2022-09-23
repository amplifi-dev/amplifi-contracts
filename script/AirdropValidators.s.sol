// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";

import {Types} from "../src/Types.sol";

contract AirdropValidatorsScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);

        uint256 size = 12;

        address[] memory users = new address[](size);
        users[0] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[1] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[2] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[3] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[4] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[5] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[6] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[7] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[8] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[9] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[10] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;
        users[11] = 0xb2525a2D6488EA0037bB2f439959AeB3BfaF8651;

        uint256[] memory months = new uint256[](size);
        months[0] = 6;
        months[1] = 6;
        months[2] = 6;
        months[3] = 6;
        months[4] = 6;
        months[5] = 6;
        months[6] = 6;
        months[7] = 6;
        months[8] = 6;
        months[9] = 6;
        months[10] = 6;
        months[11] = 6;


        Types.FuseProduct[] memory fuseProducts = new Types.FuseProduct[](size);
        for (uint256 i = 0; i < size; i++) {
            fuseProducts[i] = Types.FuseProduct.None;
        }

        amplifiNode.airdropAmplifiers(users, months, fuseProducts);

        vm.stopBroadcast();
    }

    function runAs(address _owner) public {
        owner = _owner;
        run();
    }
}
