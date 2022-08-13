// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {BaseTest, Types} from "./BaseTest.t.sol";

contract AmplifiTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testDeployed() public {
        assertEq(amplifi.name(), "Amplifi");
        assertEq(amplifi.symbol(), "AMPLIFI");

        // TODO: Test that we have LP tokens
    }

    function testCannotTrade() public {
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(usdc);
        path[2] = address(amplifi);

        vm.prank(userOne);
        vm.expectRevert("UniswapV2: TRANSFER_FAILED");
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 1 ether}(
            0,
            path,
            address(this),
            block.timestamp
        );

        assertEq(amplifi.balanceOf(userOne), 0);
    }
}

contract AmplifiEnabledTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
        super.runEnableScript();
    }

    function buyToken(
        address userAddress,
        uint256 amount,
        address[] memory path
    ) internal {
        vm.prank(userAddress);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, userAddress, block.timestamp);
    }

    function sellToken(
        address userAddress,
        uint256 amount,
        address[] memory path
    ) internal {
        vm.startPrank(userAddress);
        amplifi.approve(address(router), type(uint256).max);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, userAddress, block.timestamp);
        vm.stopPrank();
    }

    function testCanBuyAfterEnabled() public {
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(usdc);
        path[2] = address(amplifi);

        uint256 amountBuy = 1 ether;
        uint256 amountOut = router.getAmountsOut(amountBuy, path)[2];

        buyToken(userOne, amountBuy, path);
        assertGt(amplifi.balanceOf(userOne), (amountOut * 9) / 10);
    }

    function testCanSellAfterEnabled() public {
        testCanBuyAfterEnabled();

        address[] memory path = new address[](3);
        path[0] = address(amplifi);
        path[1] = address(usdc);
        path[2] = address(weth);
        uint256 priorBalance = userOne.balance;

        uint256 amountSell = amplifi.balanceOf(userOne);
        uint256 amountOut = router.getAmountsOut(amountSell, path)[2];

        sellToken(userOne, amountSell, path);
        assertEq(amplifi.balanceOf(userOne), 0);
        assertGt(userOne.balance, priorBalance + ((amountOut * 85) / 100));
    }

    function testCollectsTaxes() public {
        // Make sure userOne has some tokens
        testCanBuyAfterEnabled();

        uint256 balanceBefore = amplifi.balanceOf(userOne);

        assertEq(amplifi.balanceOf(userTwo), 0);

        vm.prank(userOne);
        amplifi.transfer(userTwo, 100);

        assertEq(amplifi.balanceOf(userOne), balanceBefore - 100);
        assertEq(amplifi.balanceOf(userTwo), 97);
    }

    function testCollectsFees() public {
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

        uint256 operationsBalance = feeRecipients.operations.balance;
        uint256 validatorAcquisitionBalance = feeRecipients.validatorAcquisition.balance;
        uint256 PCRBalance = feeRecipients.PCR.balance;
        uint256 yieldBalance = feeRecipients.yield.balance;
        uint256 xChainValidatorAcquisitionBalance = feeRecipients.xChainValidatorAcquisition.balance;
        uint256 indexFundPoolsBalance = feeRecipients.indexFundPools.balance;
        uint256 gAMPRewardsPoolBalance = feeRecipients.gAMPRewardsPool.balance;
        uint256 OTCSwapBalance = feeRecipients.OTCSwap.balance;
        uint256 rescueFundBalance = feeRecipients.rescueFund.balance;
        uint256 protocolImprovementBalance = feeRecipients.protocolImprovement.balance;
        uint256 developersBalance = feeRecipients.developers.balance;

        address[] memory buyPath = new address[](3);
        buyPath[0] = address(weth);
        buyPath[1] = address(usdc);
        buyPath[2] = address(amplifi);

        address[] memory sellPath = new address[](3);
        sellPath[0] = address(amplifi);
        sellPath[1] = address(usdc);
        sellPath[2] = address(weth);

        for (uint256 i = 0; i < 20; i++) {
            address user = randomUsers[i];

            uint256 balancePrev = amplifi.balanceOf(user);
            vm.deal(user, 1 ether + i * 0.5 ether);
            buyToken(user, user.balance - (1 ether / 5), buyPath);
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            sellToken(user, amplifi.balanceOf(user), sellPath);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(feeRecipients.operations.balance, 2e15 + operationsBalance);
        assertGt(feeRecipients.validatorAcquisition.balance, 1e15 + validatorAcquisitionBalance);
        assertGt(feeRecipients.PCR.balance, 1e15 + PCRBalance);
        assertGt(feeRecipients.yield.balance, 1e15 + yieldBalance);
        assertGt(feeRecipients.xChainValidatorAcquisition.balance, 5e14 + xChainValidatorAcquisitionBalance);
        assertGt(feeRecipients.indexFundPools.balance, 5e14 + indexFundPoolsBalance);
        assertGt(feeRecipients.gAMPRewardsPool.balance, 5e14 + gAMPRewardsPoolBalance);
        assertGt(feeRecipients.OTCSwap.balance, 5e14 + OTCSwapBalance);
        assertGt(feeRecipients.rescueFund.balance, 5e14 + rescueFundBalance);
        assertGt(feeRecipients.protocolImprovement.balance, 5e14 + protocolImprovementBalance);
        assertGt(feeRecipients.developers.balance, 1e15 + developersBalance);
    }

    function testCanSetFees() public {
        (, , , uint16 yield, , , , uint16 OTCSwap, , , uint16 developers) = amplifi.fees();

        assertEq(yield, 87);
        assertEq(OTCSwap, 44);
        assertEq(developers, 200);

        vm.prank(owner);

        Types.Fees memory fees = Types.Fees(200, 100, 100, 100, 50, 50, 50, 50, 50, 50, 100);

        amplifi.setFees(fees);

        (, , , yield, , , , OTCSwap, , , developers) = amplifi.fees();

        assertEq(yield, 100);
        assertEq(OTCSwap, 50);
        assertEq(developers, 100);
    }
}
