// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi, AmplifiNode, BaseTest, Types} from "./BaseTest.t.sol";

contract AmplifiNodeTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
        super.runEnableScript();
    }

    function createAmplifier(uint256 _months) public returns (uint256 id) {
        return createAmplifier(_months, userOne);
    }

    function createAmplifier(uint256 _months, address _user) public returns (uint256 id) {
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(usdc);
        path[2] = address(amplifi);

        vm.startPrank(_user);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 10 ether}(0, path, _user, block.timestamp);
        assertGt(amplifi.balanceOf(_user), 20);

        uint256 amplifiBalanceBefore = amplifi.balanceOf(_user);
        uint256 amplifierBalance = amplifiNode.balanceOf(_user);
        uint256 totalAmplifiers = amplifiNode.totalAmplifiers();
        (, address validatorAcquisition, , , , , , , , , ) = amplifi.feeRecipients();
        uint256 validatorAcquisitionBalanceBefore = validatorAcquisition.balance;

        uint256 totalSupplyBefore = amplifi.totalSupply();

        amplifi.approve(address(amplifiNode), type(uint256).max);
        id = amplifiNode.createAmplifier{value: 6e15 * _months}(_months);

        assertEq(amplifi.balanceOf(_user), amplifiBalanceBefore - 20e18);
        assertEq(amplifi.totalSupply(), totalSupplyBefore - 20e18);
        assertEq(amplifiNode.totalAmplifiers(), totalAmplifiers + 1);
        assertEq(amplifiNode.balanceOf(_user), amplifierBalance + 1);
        (, address minter, , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(minter, _user);
        assertEq(amplifiNode.ownedAmplifiers(_user, amplifierBalance), id);
        assertEq(validatorAcquisition.balance, validatorAcquisitionBalanceBefore + amplifiNode.renewalFee() * _months);

        vm.stopPrank();
    }

    function fuseAmplifier(uint256 _months, Types.FuseProduct _fuseProduct) public {
        fuseAmplifier(_months, _fuseProduct, userOne);
    }

    function fuseAmplifier(
        uint256 _id,
        Types.FuseProduct _fuseProduct,
        address _user
    ) public {
        vm.startPrank(_user);

        (, address validatorAcquisition, , , , , , , , , ) = amplifi.feeRecipients();
        uint256 validatorAcquisitionBalanceBefore = validatorAcquisition.balance;

        (Types.FuseProduct fuseProduct, , , , , , uint256 fused, , ) = amplifiNode.amplifiers(_id);
        assertEq(uint256(fuseProduct), uint256(Types.FuseProduct.None));
        assertEq(fused, 0);

        amplifiNode.fuseAmplifier{value: 7e15}(_id, _fuseProduct);

        (fuseProduct, , , , , , fused, , ) = amplifiNode.amplifiers(_id);
        assertEq(uint256(fuseProduct), uint256(_fuseProduct));
        assertEq(fused, block.timestamp);

        assertEq(validatorAcquisition.balance, validatorAcquisitionBalanceBefore + amplifiNode.fuseFee());

        vm.stopPrank();
    }

    function testCreateAmplifier() public {
        createAmplifier(1);
    }

    function testCannotCreateWithoutApprovalTokens() public {
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(usdc);
        path[2] = address(amplifi);

        vm.startPrank(userOne);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 10 ether}(0, path, userOne, block.timestamp);

        vm.expectRevert(stdError.arithmeticError);
        amplifiNode.createAmplifier{value: 6e15}(1);

        vm.stopPrank();
    }

    function testCreateAmplifiersBatch() public {
        createAmplifier(1);

        vm.startPrank(userOne);
        uint256 amplifiBalanceBefore = amplifi.balanceOf(userOne);
        assertEq(amplifiNode.balanceOf(userOne), 1);

        amplifiNode.createAmplifierBatch{value: (6e15 * 6) * 10}(10, 6);

        assertEq(amplifiNode.balanceOf(userOne), 11);

        assertEq(amplifi.balanceOf(userOne), amplifiBalanceBefore - (20e18 * 10));

        vm.stopPrank();
    }

    function testCreateMultipleAmplifiersWithFee() public {
        createAmplifier(1);

        vm.startPrank(owner);
        amplifiNode.setFees(
            amplifiNode.renewalFee(),
            amplifiNode.renewalFee(),
            amplifiNode.fuseFee(),
            amplifiNode.claimFee()
        );
        vm.stopPrank();

        vm.startPrank(userOne);
        assertEq(amplifiNode.balanceOf(userOne), 1);

        vm.expectRevert("Invalid Ether value provided");
        amplifiNode.createAmplifierBatch{value: (6e15 * 6) * 10}(10, 6);
        assertEq(amplifiNode.balanceOf(userOne), 1);

        amplifiNode.createAmplifierBatch{value: (6e15 * 6 + 6e15) * 10}(10, 6);
        assertEq(amplifiNode.balanceOf(userOne), 11);

        vm.stopPrank();
    }

    function testCannotCreateMultipleAmplifiersWithWrongValue() public {
        createAmplifier(1);

        vm.startPrank(userOne);
        assertEq(amplifiNode.balanceOf(userOne), 1);

        vm.expectRevert("Invalid Ether value provided");
        amplifiNode.createAmplifierBatch{value: 6e15 * 10}(10, 6);

        assertEq(amplifiNode.balanceOf(userOne), 1);

        vm.stopPrank();
    }

    function testCanotCreateAmplifierLongerThan6Months() public {
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(usdc);
        path[2] = address(amplifi);

        vm.startPrank(userOne);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 1 ether}(0, path, userOne, block.timestamp);
        assertGt(amplifi.balanceOf(userOne), 20);

        uint256 amplifierBalance = amplifiNode.balanceOf(userOne);
        uint256 totalAmplifiers = amplifiNode.totalAmplifiers();

        uint256 totalSupplyBefore = amplifi.totalSupply();

        amplifi.approve(address(amplifiNode), type(uint256).max);

        vm.expectRevert("Must be 1-6 months");
        amplifiNode.createAmplifier{value: 6e15 * 7}(7);

        assertEq(amplifi.totalSupply(), totalSupplyBefore);
        assertEq(amplifiNode.totalAmplifiers(), totalAmplifiers);
        assertEq(amplifiNode.balanceOf(userOne), amplifierBalance);
        vm.stopPrank();
    }

    function testCanotCreateMoreThanMaxAmplifiers() public {
        for (uint256 i = 0; i < amplifiNode.maxAmplifiersPerMinter(); i++) {
            createAmplifier(1);
        }

        vm.startPrank(userOne);
        vm.expectRevert("Too many amplifiers");
        amplifiNode.createAmplifier{value: 6e15}(1);
        vm.stopPrank();
    }

    function testMustSendCorrectAmount() public {
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(usdc);
        path[2] = address(amplifi);

        vm.startPrank(userOne);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 1 ether}(0, path, userOne, block.timestamp);
        assertGt(amplifi.balanceOf(userOne), 20);

        uint256 amplifierBalance = amplifiNode.balanceOf(userOne);
        uint256 totalAmplifiers = amplifiNode.totalAmplifiers();

        uint256 totalSupplyBefore = amplifi.totalSupply();

        amplifi.approve(address(amplifiNode), type(uint256).max);

        vm.expectRevert("Invalid Ether value provided");
        amplifiNode.createAmplifier{value: 6e15 * 2}(1);

        vm.expectRevert("Invalid Ether value provided");
        amplifiNode.createAmplifier{value: 6e15}(2);

        assertEq(amplifi.totalSupply(), totalSupplyBefore);
        assertEq(amplifiNode.totalAmplifiers(), totalAmplifiers);
        assertEq(amplifiNode.balanceOf(userOne), amplifierBalance);
        vm.stopPrank();
    }

    function testRenewAmplifier() public {
        createAmplifier(1);

        skip(30 days);

        vm.startPrank(userOne);
        amplifiNode.renewAmplifier{value: 6e15 * 3}(0, 3);
        vm.stopPrank();
    }

    function testRenewAmplifiersBatch() public {
        createAmplifier(1);

        vm.startPrank(userOne);
        assertEq(amplifiNode.balanceOf(userOne), 1);

        uint256[] memory ids = amplifiNode.createAmplifierBatch{value: (6e15 * 6) * 10}(10, 6);

        assertEq(amplifiNode.balanceOf(userOne), 11);

        skip(30 days);

        amplifiNode.renewAmplifierBatch{value: (6e15 * 6) * 10}(ids, 6);

        // TODO: Some assertions to make sure renewing actually works

        vm.stopPrank();
    }

    function testRenewAmplifierTwoMonths() public {
        createAmplifier(2);

        skip(60 days);

        vm.startPrank(userOne);
        amplifiNode.renewAmplifier{value: 6e15 * 3}(0, 3);
        vm.stopPrank();
    }

    function testRenewAmplifierDuringGracePeriod() public {
        createAmplifier(1);

        skip(32 days);

        vm.startPrank(userOne);
        amplifiNode.renewAmplifier{value: 6e15 * 3}(0, 3);
        vm.stopPrank();
    }

    function testCannotRenewIfDoesntExist() public {
        vm.startPrank(userOne);
        vm.expectRevert("Invalid ownership");
        amplifiNode.renewAmplifier{value: 6e15 * 3}(0, 3);
        vm.stopPrank();
    }

    function testCannotRenewAfterGracePeriod() public {
        createAmplifier(1);

        skip(60 days + 1 minutes);

        vm.startPrank(userOne);
        vm.expectRevert("Grace period expired");
        amplifiNode.renewAmplifier{value: 6e15 * 3}(0, 3);
        vm.stopPrank();
    }

    function testCannotRenewAmplifierLongerThan6Months() public {
        createAmplifier(1);

        skip(30 days);

        vm.startPrank(userOne);
        vm.expectRevert("Too many months");
        amplifiNode.renewAmplifier{value: 6e15 * 7}(0, 7);
        vm.stopPrank();
    }

    function testCannotClaimFromExpiredAmplifier() public {
        createAmplifier(1);

        skip(32 days);

        uint256 balanceBefore = amplifi.balanceOf(userOne);

        vm.startPrank(userOne);
        vm.expectRevert("Amplifier expired");
        amplifiNode.claimAMPLIFI(0);
        vm.stopPrank();

        assertEq(amplifi.balanceOf(userOne), balanceBefore);
    }

    function testClaimFromAmplifier() public {
        createAmplifier(1);

        skip(15 days);

        uint256 amplifiBalanceBefore = amplifi.balanceOf(userOne);

        (address operations, , , , , , , , , , address developers) = amplifi.feeRecipients();

        uint256 developersUSDCBalanceBefore = usdc.balanceOf(developers);
        uint256 operationsUSDCBalanceBefore = usdc.balanceOf(operations);

        vm.startPrank(userOne);
        amplifiNode.claimAMPLIFI(0);
        vm.stopPrank();

        assertGt(amplifi.balanceOf(userOne), amplifiBalanceBefore);
        assertGt(usdc.balanceOf(developers), developersUSDCBalanceBefore);
        assertGt(usdc.balanceOf(operations), operationsUSDCBalanceBefore);
    }

    function testClaimFromAmplifierSecondClaimNotAsLarge() public {
        createAmplifier(1);

        skip(10 days);

        uint256 amplifiBalanceBefore = amplifi.balanceOf(userOne);

        vm.startPrank(userOne);
        amplifiNode.claimAMPLIFI(0);
        vm.stopPrank();

        uint256 firstIncrease = amplifi.balanceOf(userOne) - amplifiBalanceBefore;

        assertGt(amplifi.balanceOf(userOne), amplifiBalanceBefore);

        skip(10 days);

        uint256 amplifiBalanceAfterFirst = amplifi.balanceOf(userOne);

        vm.startPrank(userOne);
        amplifiNode.claimAMPLIFI(0);
        vm.stopPrank();

        uint256 secondIncrease = amplifi.balanceOf(userOne) - amplifiBalanceAfterFirst;

        assertGt(firstIncrease, secondIncrease);
    }

    function testClaimFromAmplifierManyTimes() public {
        uint256 id = createAmplifier(6);

        vm.startPrank(userOne);
        skip(73 days);
        amplifiNode.renewAmplifier{value: 6e15 * 3}(id, 3);

        uint256 amplifiBalanceBefore;
        uint256 increase;
        uint256 previousIncrease;

        for (uint256 i = 0; i < 20; i++) {
            skip(5 days);

            amplifiBalanceBefore = amplifi.balanceOf(userOne);
            amplifiNode.claimAMPLIFI(0);
            assertGt(amplifi.balanceOf(userOne), amplifiBalanceBefore);

            increase = amplifi.balanceOf(userOne) - amplifiBalanceBefore;
            assertGt(increase, 0);

            if (previousIncrease != 0) {
                assertGt(previousIncrease, increase);
            }

            previousIncrease = increase;
        }

        skip(5 days);

        amplifiBalanceBefore = amplifi.balanceOf(userOne);
        amplifiNode.claimAMPLIFI(0);
        assertGt(amplifi.balanceOf(userOne), amplifiBalanceBefore);

        increase = amplifi.balanceOf(userOne) - amplifiBalanceBefore;
        assertGt(increase, 0);
        assertEq(previousIncrease, increase);

        vm.stopPrank();
    }

    function testCanFuseAmplifier() public {
        uint256 id = createAmplifier(1);
        fuseAmplifier(id, Types.FuseProduct.OneYear);
    }

    function testCanUnlockFusedAmplifier() public {
        uint256 id = createAmplifier(6);
        fuseAmplifier(id, Types.FuseProduct.OneYear);

        vm.startPrank(owner);
        amplifiNode.fusePools(Types.FuseProduct.OneYear).deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(userOne);

        uint256 amplifiBalance = amplifi.balanceOf(userOne);

        skip(30 days * 6);

        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        uint256 firstBalance = userOne.balance;
        amplifiNode.claimETH(id);
        assertGt(userOne.balance, firstBalance);
        assertEq(amplifi.balanceOf(userOne), amplifiBalance);

        skip(30 days * 6);
        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        (Types.FuseProduct fuseProduct, , , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(uint256(fuseProduct), uint256(Types.FuseProduct.OneYear));

        skip(5 days);
        amplifiNode.renewAmplifier{value: 6e15 * 1}(id, 1);

        uint256 secondBalance = userOne.balance;
        amplifiNode.claimETH(id);
        assertGt(userOne.balance, secondBalance);
        // The margin of error just comes from gas costs
        assertApproxEqAbs(userOne.balance, firstBalance + 10 ether, 0.045 ether);
        assertEq(amplifi.balanceOf(userOne), amplifiBalance + amplifiNode.boosts(Types.FuseProduct.OneYear));

        (fuseProduct, , , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(uint256(fuseProduct), uint256(Types.FuseProduct.None));

        vm.stopPrank();
    }

    function testCanUnlockFusedAmplifierThatGetsToppedUp() public {
        uint256 id = createAmplifier(6);
        fuseAmplifier(id, Types.FuseProduct.OneYear);

        vm.startPrank(owner);
        amplifiNode.fusePools(Types.FuseProduct.OneYear).deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(userOne);

        skip(30 days * 6);

        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        uint256 firstBalance = userOne.balance;
        amplifiNode.claimETH(id);
        assertGt(userOne.balance, firstBalance);

        vm.stopPrank();

        vm.startPrank(owner);
        amplifiNode.fusePools(Types.FuseProduct.OneYear).deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(userOne);

        skip(30 days * 6);
        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        (Types.FuseProduct fuseProduct, , , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(uint256(fuseProduct), uint256(Types.FuseProduct.OneYear));

        skip(5 days);
        amplifiNode.renewAmplifier{value: 6e15 * 1}(id, 1);

        uint256 secondBalance = userOne.balance;
        amplifiNode.claimETH(id);
        assertGt(userOne.balance, secondBalance);
        // The margin of error just comes from gas costs
        assertApproxEqAbs(userOne.balance, firstBalance + 20 ether, 0.045 ether);

        (fuseProduct, , , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(uint256(fuseProduct), uint256(Types.FuseProduct.None));

        vm.stopPrank();
    }

    function testCanClaimFusedAmplifierHalfWayThatGetsToppedUp() public {
        uint256 id = createAmplifier(6);
        fuseAmplifier(id, Types.FuseProduct.OneYear);

        vm.startPrank(owner);
        amplifiNode.fusePools(Types.FuseProduct.OneYear).deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(userOne);

        skip(30 days * 6);

        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        skip(2.5 days);
        uint256 firstBalance = userOne.balance;
        amplifiNode.claimETH(id);
        assertGt(userOne.balance, firstBalance);
        // The margin of error just comes from gas costs
        assertApproxEqAbs(userOne.balance, firstBalance + 5 ether, 0.045 ether);

        vm.stopPrank();

        vm.startPrank(owner);
        amplifiNode.fusePools(Types.FuseProduct.OneYear).deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(userOne);

        skip(30 days * 3);
        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        (Types.FuseProduct fuseProduct, , , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(uint256(fuseProduct), uint256(Types.FuseProduct.OneYear));

        skip(1.25 days);
        uint256 secondBalance = userOne.balance;
        amplifiNode.claimETH(id);
        assertGt(userOne.balance, secondBalance);
        // The margin of error just comes from gas costs
        assertApproxEqAbs(userOne.balance, firstBalance + 15 ether, 0.045 ether);

        vm.stopPrank();
    }

    function testCanClaimFusedAmplifierMultipleUsers() public {
        uint256 idOne = createAmplifier(6, userOne);
        fuseAmplifier(idOne, Types.FuseProduct.OneYear, userOne);

        uint256 idTwo = createAmplifier(6, userTwo);
        fuseAmplifier(idTwo, Types.FuseProduct.OneYear, userTwo);

        vm.startPrank(owner);
        amplifiNode.fusePools(Types.FuseProduct.OneYear).deposit{value: 10 ether}();
        vm.stopPrank();

        skip(30 days * 6);

        vm.startPrank(userOne);
        amplifiNode.renewAmplifier{value: 6e15 * 6}(idOne, 6);
        vm.stopPrank();

        vm.startPrank(userTwo);
        amplifiNode.renewAmplifier{value: 6e15 * 6}(idTwo, 6);
        vm.stopPrank();

        skip(2.5 days);

        vm.startPrank(userOne);
        uint256 firstBalance = userOne.balance;
        amplifiNode.claimETH(idOne);
        uint256 increaseOne = userOne.balance - firstBalance;
        assertGt(userOne.balance, firstBalance);
        assertApproxEqAbs(increaseOne, 2.5 ether, 0.045 ether);
        vm.stopPrank();

        vm.startPrank(userTwo);
        amplifiNode.renewAmplifier{value: 6e15 * 6}(idTwo, 6);
        firstBalance = userTwo.balance;
        amplifiNode.claimETH(idTwo);
        uint256 increaseTwo = userTwo.balance - firstBalance;
        assertGt(userTwo.balance, firstBalance);
        assertApproxEqAbs(increaseTwo, 2.5 ether, 0.045 ether);
        assertEq(increaseOne, increaseTwo);
        vm.stopPrank();
    }

    function testCannotClaimETHFromFusedAmplifierBefore90Days() public {
        uint256 id = createAmplifier(6);
        fuseAmplifier(id, Types.FuseProduct.OneYear);

        vm.startPrank(userOne);

        skip(30 days);
        vm.expectRevert("Cannot claim ETH yet");
        amplifiNode.claimETH(id);

        vm.stopPrank();
    }

    function testCannotClaimETHFromUnfusedAmplifier() public {
        uint256 id = createAmplifier(6);

        vm.startPrank(userOne);

        skip(30 days);
        vm.expectRevert("Must be fused");
        amplifiNode.claimETH(id);

        vm.stopPrank();
    }

    function testCannotClaimAMPLIFIFromFusedAmplifier() public {
        uint256 id = createAmplifier(6);
        fuseAmplifier(id, Types.FuseProduct.OneYear);

        uint256 amplifiBalanceBefore = amplifi.balanceOf(userOne);

        vm.startPrank(userOne);
        vm.expectRevert("Must be unfused");
        amplifiNode.claimAMPLIFI(id);
        vm.stopPrank();

        assertEq(amplifi.balanceOf(userOne), amplifiBalanceBefore);
    }

    function testCanClaimAMPLIFIFromFusedAmplifierAfterUnlock() public {
        uint256 id = createAmplifier(6);
        fuseAmplifier(id, Types.FuseProduct.OneYear);

        vm.startPrank(owner);
        amplifiNode.fusePools(Types.FuseProduct.OneYear).deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(userOne);

        skip(30 days * 6);

        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        uint256 firstBalance = userOne.balance;
        amplifiNode.claimETH(id);
        assertGt(userOne.balance, firstBalance);

        skip(30 days * 6);
        amplifiNode.renewAmplifier{value: 6e15 * 6}(id, 6);

        (Types.FuseProduct fuseProduct, , , , , , , , ) = amplifiNode.amplifiers(id);
        assertEq(uint256(fuseProduct), uint256(Types.FuseProduct.OneYear));

        skip(5 days);
        amplifiNode.renewAmplifier{value: 6e15 * 1}(id, 1);

        amplifiNode.claimETH(id);

        uint256 amplifiBalanceBefore = amplifi.balanceOf(userOne);

        amplifiNode.claimAMPLIFI(id);
        vm.stopPrank();

        assertGt(amplifi.balanceOf(userOne), amplifiBalanceBefore);
    }

    function testClaimAmplifiBatch() public {
        uint256 firstAmplifier = createAmplifier(1);

        uint256 amplifiBalanceBeforeBefore = amplifi.balanceOf(userOne);
        skip(15 days);

        vm.startPrank(userOne);


        amplifiNode.claimAMPLIFI(firstAmplifier);

        uint256 balanceDifference = amplifi.balanceOf(userOne) - amplifiBalanceBeforeBefore;

        uint256[] memory ids = amplifiNode.createAmplifierBatch{value: (6e15 * 6) * 10}(10, 6);
        vm.stopPrank();

        skip(15 days);

        uint256 amplifiBalanceBefore = amplifi.balanceOf(userOne);

        (address operations, , , , , , , , , , address developers) = amplifi.feeRecipients();

        uint256 developersUSDCBalanceBefore = usdc.balanceOf(developers);
        uint256 operationsUSDCBalanceBefore = usdc.balanceOf(operations);

        vm.startPrank(userOne);
        amplifiNode.claimAMPLIFIBatch(ids);
        vm.stopPrank();

        assertGt(amplifi.balanceOf(userOne), amplifiBalanceBefore);
        assertGt(usdc.balanceOf(developers), developersUSDCBalanceBefore);
        assertGt(usdc.balanceOf(operations), operationsUSDCBalanceBefore);
        assertGt(amplifi.balanceOf(userOne) - amplifiBalanceBefore, balanceDifference * 9);
    }

    // TODO: Test claimETHBatch
}
