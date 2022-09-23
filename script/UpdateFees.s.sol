// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";
import {ScriptTypes} from "./ScriptTypes.sol";

import {FeeSplitter} from "../src/FeeSplitter.sol";
import {Types} from "../src/Types.sol";

contract UpdateFeesScript is BaseScript {
    function run() public returns (ScriptTypes.FeeSplitterContracts memory contracts) {
        vm.startBroadcast(owner);

        Types.Fees memory fees;

        fees.operations = 50;
        fees.validatorAcquisition = 50;
        fees.PCR = 25;
        fees.yield = 25;
        fees.xChainValidatorAcquisition = 10;
        fees.indexFundPools = 10;
        fees.gAMPRewardsPool = 50;
        fees.OTCSwap = 10;
        fees.rescueFund = 10;
        fees.protocolImprovement = 10;
        fees.developers = 50;
        amplifi.setFees(fees);

        uint256 size = 2;

        address[] memory recipients = new address[](size);
        recipients[0] = 0x682Ce32507D2825A540Ad31dC4C2B18432E0e5Bd;
        recipients[1] = 0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17;

        uint16[] memory shares = new uint16[](size);
        shares[0] = 6;
        shares[1] = 4;

        FeeSplitter feeSplitter = new FeeSplitter(recipients, shares);
        contracts.feeSplitter = feeSplitter;
        assert(feeSplitter.totalShares() == 10);

        Types.AmplifierFeeRecipients memory amplifierFeeRecipients;

        amplifierFeeRecipients.operations = 0xc766B8c9741BC804FCc378FdE75560229CA3AB1E;
        amplifierFeeRecipients.validatorAcquisition = address(feeSplitter);
        amplifierFeeRecipients.developers = 0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17;
        amplifiNode.setFeeRecipients(amplifierFeeRecipients);

        amplifiNode.setFees(0.008 ether, 0.008 ether, 0.008 ether, 750);

        vm.stopBroadcast();
    }

    function runAs(address _owner) public returns (ScriptTypes.FeeSplitterContracts memory contracts) {
        owner = _owner;
        return run();
    }
}
