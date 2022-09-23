// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";

import {Amplifi} from "../src/Amplifi.sol";
import {Types} from "../src/Types.sol";

import {ScriptTypes} from "./ScriptTypes.sol";

contract ProcessFeesScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);

        uint256 ethAfter = address(amplifi).balance;

        amplifi.withdrawETH(owner);

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

        Types.Fees memory fees;
        {
            (
                uint16 operations,
                uint16 validatorAcquisition,
                uint16 PCR,
                uint16 yield,
                uint16 xChainValidatorAcquisition,
                uint16 indexFundPools,
                uint16 gAMPRewardsPool,
                uint16 OTCSwap,
                uint16 rescueFund,
                uint16 protocolImprovement,
                uint16 developers
            ) = amplifi.fees();
            fees.operations = operations;
            fees.validatorAcquisition = validatorAcquisition;
            fees.PCR = PCR;
            fees.yield = yield;
            fees.xChainValidatorAcquisition = xChainValidatorAcquisition;
            fees.indexFundPools = indexFundPools;
            fees.gAMPRewardsPool = gAMPRewardsPool;
            fees.OTCSwap = OTCSwap;
            fees.rescueFund = rescueFund;
            fees.protocolImprovement = protocolImprovement;
            fees.developers = developers;
        }
        uint256 feeTotal = amplifi.feeTotal();

        bool success;
        (success, ) = feeRecipients.operations.call{value: (ethAfter * fees.operations) / feeTotal}("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.validatorAcquisition.call{value: (ethAfter * fees.validatorAcquisition) / feeTotal}(
            ""
        );
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.PCR.call{value: (ethAfter * fees.PCR) / feeTotal}("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.yield.call{value: (ethAfter * fees.yield) / feeTotal}("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.xChainValidatorAcquisition.call{
            value: (ethAfter * fees.xChainValidatorAcquisition) / feeTotal
        }("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.indexFundPools.call{value: (ethAfter * fees.indexFundPools) / feeTotal}("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.gAMPRewardsPool.call{value: (ethAfter * fees.gAMPRewardsPool) / feeTotal}("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.OTCSwap.call{value: (ethAfter * fees.OTCSwap) / feeTotal}("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.rescueFund.call{value: (ethAfter * fees.rescueFund) / feeTotal}("");
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.protocolImprovement.call{value: (ethAfter * fees.protocolImprovement) / feeTotal}(
            ""
        );
        require(success, "Could not send ETH");
        (success, ) = feeRecipients.developers.call{value: (ethAfter * fees.developers) / feeTotal}("");
        require(success, "Could not send ETH");

        vm.stopBroadcast();
    }
}
