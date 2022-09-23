// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseScript} from "./base/BaseScript.s.sol";

contract UpdateContractSellingScript is BaseScript {
    function run() public {
        vm.startBroadcast(owner);

        amplifi.setContractSelling(amplifi.contractSellEnabled(), 325e17, amplifi.minSwapAmountToTriggerContractSell());

        assert(amplifi.contractSellEnabled() == true);
        assert(amplifi.contractSellThreshold() == 325e17);
        assert(amplifi.minSwapAmountToTriggerContractSell() == 0);

        vm.stopBroadcast();
    }
}
