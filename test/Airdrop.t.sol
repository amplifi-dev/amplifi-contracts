// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi, AmplifiNode} from "../src/Amplifi.sol";

import {BaseTestDeployed} from "./base/BaseTestDeployed.t.sol";

import {AirdropValidatorsScript} from "../script/AirdropValidators.s.sol";

contract AirdropDeployedTest is BaseTestDeployed {
    function setUp() public virtual override {
        super.setUp();
    }

    function testAirdrop() public {
        address recipient = 0x4eD58aba9B4d9a43925547AD7Ecc76D100c0Dc1e;
        assertEq(amplifiNode.balanceOf(recipient), 5);

        AirdropValidatorsScript(address(new AirdropValidatorsScript().setUp())).runAs(deployer);

        assertEq(amplifiNode.balanceOf(recipient), 10);
        uint256 id = amplifiNode.ownedAmplifiers(recipient, 0);

        (, address minter, , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(minter, recipient);
    }

    function testAirdropAndRemove() public {
        address recipient = 0x4eD58aba9B4d9a43925547AD7Ecc76D100c0Dc1e;
        assertEq(amplifiNode.balanceOf(recipient), 5);

        AirdropValidatorsScript(address(new AirdropValidatorsScript().setUp())).runAs(deployer);

        assertEq(amplifiNode.balanceOf(recipient), 10);
        uint256 id = amplifiNode.ownedAmplifiers(recipient, 0);

        (, address minter, , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(minter, recipient);

        vm.prank(owner);
        amplifiNode.removeAmplifier(id);

        (, minter, , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(minter, address(0));
        assertEq(amplifiNode.balanceOf(recipient), 9);
    }
}
