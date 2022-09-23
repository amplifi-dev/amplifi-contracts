// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {BaseScript, console2} from "./base/BaseScript.s.sol";

import {ERC20StakingPool} from "../src/ERC20StakingPool.sol";

import {Amplifi} from "../src/Amplifi.sol";

import {ScriptTypes} from "./ScriptTypes.sol";



contract DeployStakingScript is BaseScript {
    address constant amplifiUsdcUniswapAddress = 0xDF527342AaEdfC0683F4c75AD791A51e8aaFAF4a;
    uint64 constant DURATION = 180 days;

    function run() public returns (ScriptTypes.StakingContracts memory contracts) {
        vm.startBroadcast(owner);

        ERC20StakingPool singleStakingPool = new ERC20StakingPool(
            ERC20(address(amplifi)),
            ERC20(address(amplifi)),
            DURATION
        );
        // ERC20StakingPool lpStakingPool = new ERC20StakingPool(
        //     ERC20(address(amplifi)),
        //     ERC20(amplifiUsdcUniswapAddress),
        //     DURATION
        // );
        uint256 balanceBefore = amplifi.balanceOf(owner);
        amplifiNode.withdrawToken(amplifi, owner);
        uint256 withdrawnBalance = amplifi.balanceOf(owner) - balanceBefore;
        uint256 returnBalance = withdrawnBalance - 1000 ether;
        uint256 stakingBalance = 1000 ether;

        amplifi.transfer(address(amplifiNode), returnBalance);

        amplifi.transfer(address(singleStakingPool), stakingBalance);
        singleStakingPool.setRewardDistributor(owner, true);
        singleStakingPool.notifyRewardAmount(stakingBalance);
        contracts.singleStakingPool = singleStakingPool;

        // amplifi.transfer(address(lpStakingPool), stakingBalance);
        // lpStakingPool.setRewardDistributor(owner, true);
        // lpStakingPool.notifyRewardAmount(stakingBalance);
        // contracts.lpStakingPool = lpStakingPool;

        console2.log("Single Staking: ", address(contracts.singleStakingPool));
        // console2.log("LP Staking: ", address(contracts.lpStakingPool));
        vm.stopBroadcast();
    }

    function runAs(address _owner) public returns (ScriptTypes.StakingContracts memory contracts) {
        owner = _owner;
        return run();
    }
}
