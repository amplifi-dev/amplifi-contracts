// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";
import {ScriptTypes} from "./ScriptTypes.sol";

import {IAmplifiNode} from "../src/interfaces/IAmplifiNode.sol";
import {gAMP} from "../src/gAMP.sol";
import {Types} from "../src/Types.sol";

contract DeploygAMPScript is BaseScript {
    function run() public returns (ScriptTypes.gAMPContracts memory contracts) {
        vm.startBroadcast(owner);

        gAMP oldGamp = gAMP(payable(0x7a452c1f6f2D8c755FA884C0488f6AaCfC1A702A));

        uint256 oldBalance = address(oldGamp).balance;

        oldGamp.withdrawETH(owner);

        uint256 lastPot = block.timestamp - 26 days;

        gAMP gamp = new gAMP(IAmplifiNode(address(amplifiNode)), lastPot);
        contracts.gamp = gamp;

        Types.FeeRecipients memory feeRecipients;
        {
            (
                address operations,
                address validatorAcquisition,
                address PCR,
                address yield,
                address xChainValidatorAcquisition,
                address indexFundPools,
                address gAMPRewardsPool,
                address OTCSwap,
                address rescueFund,
                address protocolImprovement,
                address developers
            ) = amplifi.feeRecipients();
            feeRecipients.operations = operations;
            feeRecipients.validatorAcquisition = validatorAcquisition;
            feeRecipients.PCR = PCR;
            feeRecipients.yield = yield;
            feeRecipients.xChainValidatorAcquisition = xChainValidatorAcquisition;
            feeRecipients.indexFundPools = indexFundPools;
            feeRecipients.gAMPRewardsPool = gAMPRewardsPool;
            feeRecipients.OTCSwap = OTCSwap;
            feeRecipients.rescueFund = rescueFund;
            feeRecipients.protocolImprovement = protocolImprovement;
            feeRecipients.developers = developers;
        }

        feeRecipients.gAMPRewardsPool = address(gamp);
        amplifi.setFeeRecipients(feeRecipients);

        (, , , , , , address newgAMPRewardsPool, , , , ) = amplifi.feeRecipients();
        assert(newgAMPRewardsPool == address(gamp));

        (bool success, ) = address(gamp).call{value: oldBalance}("");
        require(success, "Could not send ETH");

        vm.stopBroadcast();
    }

    function runAs(address _owner) public returns (ScriptTypes.gAMPContracts memory contracts) {
        owner = _owner;
        return run();
    }
}
