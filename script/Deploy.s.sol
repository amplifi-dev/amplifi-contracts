// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript, console2} from "./base/BaseScript.s.sol";

import {Amplifi} from "../src/Amplifi.sol";

import {ScriptTypes} from "./ScriptTypes.sol";

contract DeployScript is BaseScript {
    function run() public returns (ScriptTypes.Contracts memory contracts) {
        vm.startBroadcast(owner);

        address gAMPVault = 0x69FA7c7198CB4EB1A032D0555104220B193370aB;

        contracts.amplifi = new Amplifi(address(router), usdc, gAMPVault);

        contracts.amplifi.amplifiNode().approveRouter();

        contracts.amplifi.approve(address(contracts.amplifi.router()), type(uint256).max);
        contracts.amplifi.USDC().approve(address(contracts.amplifi.router()), type(uint256).max);

        contracts.amplifi.router().addLiquidity(
            address(contracts.amplifi.USDC()),
            address(contracts.amplifi),
            150_000e6,
            11_500e18,
            150_000e6,
            11_500e18,
            owner,
            block.timestamp + 5 minutes
        );

        vm.stopBroadcast();

        console2.log("Amplifi: ", address(contracts.amplifi));
        console2.log("AmplifiNode: ", address(contracts.amplifi.amplifiNode()));
    }
}
