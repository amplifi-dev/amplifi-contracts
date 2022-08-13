// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/old/MicroValidator.sol";

contract GetValidatorsScript is Script {
    function run() public view {
        MicroValidator v1 = MicroValidator(payable(0x55dBfaF811f15bc790c52168D278cFCFD9Fc6f24));

        uint256 totalNodes = 165;
        for (uint256 i = 0; i <= totalNodes; i++) {
            MicroValidator.Validator memory validator = v1.getValidator(i);

            console.log("id", validator.id);
            console.log("minter", validator.minter);
            console.log("created", validator.created);
            console.log("lastClaimMicrov", validator.lastClaimMicrov);
            console.log("lastClaimEth", validator.lastClaimEth);
            console.log("numClaimsMicrov", validator.numClaimsMicrov);
            console.log("renewalExpiry", validator.renewalExpiry);
            console.log("fuseProduct", validator.fuseProduct);
            console.log("fuseCreated", validator.fuseCreated);
            console.log("fuseUnlocks", validator.fuseUnlocks);
            console.log("fuseUnlocked", validator.fuseUnlocked);
        }
    }
}
