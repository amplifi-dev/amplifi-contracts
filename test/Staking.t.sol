// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi, AmplifiNode, BaseTestLocal, Types} from "./base/BaseTestLocal.t.sol";
import {BaseTestDeployed} from "./base/BaseTestDeployed.t.sol";

import {UpdateRatesScript} from "../script/UpdateRates.s.sol";

import {DeployStakingScript} from "../script/DeployStaking.s.sol";

import {ScriptTypes} from "../script/ScriptTypes.sol";

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract StakingDeployedTest is BaseTestDeployed {
    ScriptTypes.StakingContracts stakingContracts;

    function setUp() public virtual override {
        super.setUp();
        stakingContracts = DeployStakingScript(address(new DeployStakingScript().setUp())).runAs(deployer);
    }

    function testSingleStaking() public {
        vm.startPrank(owner);
        amplifi.mint(100 ether);
        amplifi.transfer(userOne, 100 ether);
        vm.stopPrank();

        vm.startPrank(userOne);
        assertEq(amplifi.balanceOf(userOne), 100 ether);
        amplifi.approve(address(stakingContracts.singleStakingPool), type(uint256).max);
        stakingContracts.singleStakingPool.stake(amplifi.balanceOf(userOne));
        assertEq(amplifi.balanceOf(userOne), 0);

        skip(7 days);

        uint256 beforeBalance = amplifi.balanceOf(userOne);
        stakingContracts.singleStakingPool.getReward();

        uint256 rewardAmount = amplifi.balanceOf(userOne) - beforeBalance;
        assertGt(rewardAmount, 0);

        assertEq(amplifi.balanceOf(userOne), beforeBalance + rewardAmount);
        stakingContracts.singleStakingPool.exit();
        assertGt(amplifi.balanceOf(userOne), beforeBalance + rewardAmount);

        vm.stopPrank();
    }


    function testStakingWithTopup() public {
        vm.startPrank(owner);
        amplifi.mint(100 ether);
        amplifi.transfer(userOne, 100 ether);
        vm.stopPrank();


        vm.startPrank(userOne);
        assertEq(amplifi.balanceOf(userOne), 100 ether);
        amplifi.approve(address(stakingContracts.singleStakingPool), type(uint256).max);
        stakingContracts.singleStakingPool.stake(amplifi.balanceOf(userOne));
        assertEq(amplifi.balanceOf(userOne), 0);

        skip(7 days);

        uint256 earnedSoFar = stakingContracts.singleStakingPool.earned(userOne);
        vm.stopPrank();


        vm.startPrank(owner);
        amplifiNode.withdrawToken(IERC20(address(amplifi)), owner);
        amplifi.transfer(address(stakingContracts.singleStakingPool), 5000 ether);
        stakingContracts.singleStakingPool.notifyRewardAmount(5000 ether);
        vm.stopPrank();


        vm.startPrank(userOne);
        uint256 earnedAfterTopup = stakingContracts.singleStakingPool.earned(userOne);
        assertEq(earnedSoFar, earnedAfterTopup);

        skip(7 days);

        uint256 earnedAfterTopupAndWait = stakingContracts.singleStakingPool.earned(userOne);
        assertGt(earnedAfterTopupAndWait, earnedAfterTopup * 2);
        vm.stopPrank();
    }

    function testAddLiq() internal {
        vm.startPrank(userTwo);

        // obtain some USDC for user2 to add
        address[] memory buyUsdcPath = new address[](2);
        buyUsdcPath[0] = WETH;
        buyUsdcPath[1] = USDC;

        amplifi.router().swapExactETHForTokensSupportingFeeOnTransferTokens{value: 10 ether}(
            0,
            buyUsdcPath,
            userTwo,
            block.timestamp + 1
        );
        uint256 userTwoUsdcBalance = usdc.balanceOf(userTwo);

        // approve both tokens on router
        usdc.approve(address(amplifi.router()), type(uint256).max);
        amplifi.approve(address(amplifi.router()), type(uint256).max);

        // calculate rough price of USDC in amplifi
        address[] memory buyAmplifiPath = new address[](2);
        buyAmplifiPath[0] = USDC;
        buyAmplifiPath[1] = address(amplifi);

        uint256 amplifiPerUSDC = amplifi.router().getAmountsOut(1 * 10**6, buyAmplifiPath)[1];

        uint256 amountAmplifiAdd = (amplifiPerUSDC * userTwoUsdcBalance) / 10**6;

        // mint requisite amount of Amplifi to userTwo
        vm.stopPrank();
        vm.startPrank(owner);
        amplifi.mint(amountAmplifiAdd);
        amplifi.transfer(userTwo, amountAmplifiAdd);
        vm.stopPrank();

        // add liquidity
        vm.startPrank(userTwo);
        assertEq(IERC20(amplifi.pair()).balanceOf(userTwo), 0);

        amplifi.router().addLiquidity(
            USDC,
            address(amplifi),
            usdc.balanceOf(userTwo),
            amountAmplifiAdd,
            (usdc.balanceOf(userTwo) * 99) / 100,
            (amountAmplifiAdd * 99) / 100,
            userTwo,
            block.timestamp + 1
        );

        assertGt(IERC20(amplifi.pair()).balanceOf(userTwo), 0);

        vm.stopPrank();
    }

    function testLpStaking() internal {
        testAddLiq();
        vm.startPrank(userTwo);

        IERC20 lpToken = IERC20(amplifi.pair());
        console2.log(lpToken.balanceOf(userTwo));
        lpToken.approve(address(stakingContracts.lpStakingPool), type(uint256).max);

        stakingContracts.lpStakingPool.stake(lpToken.balanceOf(userTwo));
        assertEq(lpToken.balanceOf(userTwo), 0);

        skip(7 days);

        uint256 beforeBalance = amplifi.balanceOf(userTwo);
        stakingContracts.lpStakingPool.getReward();

        uint256 rewardAmount = amplifi.balanceOf(userTwo) - beforeBalance;
        assertGt(rewardAmount, 0);

        assertEq(lpToken.balanceOf(userTwo), 0);
        stakingContracts.lpStakingPool.exit();
        assertGt(lpToken.balanceOf(userTwo), 0);

        vm.stopPrank();
    }
}
