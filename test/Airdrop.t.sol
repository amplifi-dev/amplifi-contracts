// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi, AmplifiNode} from "../src/Amplifi.sol";

import {BaseTest} from "./BaseTest.t.sol";

import {AirdropValidatorsScript} from "../script/AirdropValidators.s.sol";

contract AirdropTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
        super.runEnableScript();
    }

    function testAirdrop() public {
        address recipient = 0x874b0729bA1f1767100048dF21B8575Cc0Ae3aC3;
        assertEq(amplifiNode.balanceOf(recipient), 3);

        AirdropValidatorsScript airdropValidatorsScript = new AirdropValidatorsScript();
        airdropValidatorsScript.run(amplifi);

        assertEq(amplifiNode.balanceOf(recipient), 5);
        uint256 id = amplifiNode.ownedAmplifiers(recipient, 0);

        (, address minter, , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(minter, recipient);
    }

    function testAirdropAndRemove() public {
        address recipient = 0x874b0729bA1f1767100048dF21B8575Cc0Ae3aC3;
        assertEq(amplifiNode.balanceOf(recipient), 3);

        AirdropValidatorsScript airdropValidatorsScript = new AirdropValidatorsScript();
        airdropValidatorsScript.run(amplifi);

        assertEq(amplifiNode.balanceOf(recipient), 5);
        uint256 id = amplifiNode.ownedAmplifiers(recipient, 0);

        (, address minter, , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(minter, recipient);

        vm.prank(owner);
        amplifiNode.removeAmplifier(id);

        (, minter, , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(minter, address(0));
        assertEq(amplifiNode.balanceOf(recipient), 4);
    }
}
