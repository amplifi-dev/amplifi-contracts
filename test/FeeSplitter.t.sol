// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi, AmplifiNode} from "../src/Amplifi.sol";
import {FeeSplitter} from "../src/FeeSplitter.sol";

import {UpdateFeesScript} from "../script/UpdateFees.s.sol";
import {ScriptTypes} from "../script/ScriptTypes.sol";

import {BaseTestDeployed} from "./base/BaseTestDeployed.t.sol";

contract FeeSplitterDeployedTest is BaseTestDeployed {
    FeeSplitter internal feeSplitter;

    function setUp() public virtual override {
        super.setUp();

        ScriptTypes.FeeSplitterContracts memory feeSplitterContracts = UpdateFeesScript(
            address(new UpdateFeesScript().setUp())
        ).runAs(deployer);

        feeSplitter = feeSplitterContracts.feeSplitter;
    }

    function testCanUpdateFees() public {
        testUtil.be(userOne).buyAmplifi();
        uint256 balanceBefore0 = feeSplitter.recipients(0).balance;
        uint256 balanceBefore1 = feeSplitter.recipients(1).balance;

        uint256 times = 10;

        for (uint256 i = 0; i < times; i++) {
            testUtil.createAmplifier(userOne, 1);
        }

        uint256 totalCreationFees = (amplifiNode.creationFee() * times) + (amplifiNode.renewalFee() * times);

        feeSplitter.claim();

        assertEq(feeSplitter.recipients(0).balance, balanceBefore0 + ((totalCreationFees * 6) / 10));
        assertEq(feeSplitter.recipients(1).balance, balanceBefore1 + ((totalCreationFees * 4) / 10));
    }

    function testOnlyOwnerCanSetRecipients() public {
        assertEq(feeSplitter.recipients(0), 0x682Ce32507D2825A540Ad31dC4C2B18432E0e5Bd);

        uint256 size = 2;

        address[] memory recipients = new address[](size);
        recipients[0] = 0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17;
        recipients[1] = 0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17;

        uint16[] memory shares = new uint16[](size);
        shares[0] = feeSplitter.shares(0);
        shares[1] = feeSplitter.shares(1);

        vm.expectRevert("Ownable: caller is not the owner");
        feeSplitter.setRecipients(recipients, shares);

        assertEq(feeSplitter.recipients(0), 0x682Ce32507D2825A540Ad31dC4C2B18432E0e5Bd);

        vm.prank(owner);
        feeSplitter.setRecipients(recipients, shares);

        assertEq(feeSplitter.recipients(0), 0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17);
    }
}
