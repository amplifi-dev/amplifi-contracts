// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Amplifi} from "../src/Amplifi.sol";
import {gAMP} from "../src/gAMP.sol";

import {ScriptTypes} from "./ScriptTypes.sol";

contract DeployScript is Script {
    function run() public returns (ScriptTypes.Contracts memory contracts) {
        vm.startBroadcast(0x4a5c98C184dA163cFffa7F1296c913135565ad3f);

        contracts.amplifi = new Amplifi(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC on Mainnet
            // 0xaD6D458402F60fD3Bd25163575031ACDce07538D, // DAI on Ropsten
            0x69FA7c7198CB4EB1A032D0555104220B193370aB
        );

        contracts.amplifi.amplifiNode().approveRouter();

        contracts.amplifi.approve(address(contracts.amplifi.router()), type(uint256).max);
        contracts.amplifi.USDC().approve(address(contracts.amplifi.router()), type(uint256).max);

        contracts.amplifi.router().addLiquidity(
            address(contracts.amplifi.USDC()),
            address(contracts.amplifi),
            150_000e6, // Mainnet
            // 50e18, // Ropsten
            11_500e18,
            150_000e6, // Mainnet
            // 50e18, // Ropsten
            11_500e18,
            address(this), // TODO: Set to 0x4a5c98C184dA163cFffa7F1296c913135565ad3f, maybe raise an issue in foundry?
            block.timestamp + 5 minutes
        );

        vm.stopBroadcast();

        console2.log("Amplifi: ", address(contracts.amplifi));
        console2.log("AmplifiNode: ", address(contracts.amplifi.amplifiNode()));
    }
}
