// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi, AmplifiNode} from "../src/Amplifi.sol";
import {gAMP} from "../src/gAMP.sol";
import {Types} from "../src/Types.sol";

import {DeploygAMPScript} from "../script/DeploygAMP.s.sol";
import {ScriptTypes} from "../script/ScriptTypes.sol";

import {BaseTestDeployed} from "./base/BaseTestDeployed.t.sol";

contract gAMPDeployedTest is BaseTestDeployed {
    address constant gAMPTeamWallet = 0x9f3717CDB4ab19da03845E8a86668BEA8bab840B;
    address constant gAMPDevWallet = 0x3460E67b0c5740ef21E390E681b3160Be372a016;

    gAMP internal gamp;

    event PotAccrued(uint256 potAmount);
    event Claimed(address indexed claimant, uint256 indexed potBlock, uint256 amount);

    function setUp() public virtual override {
        super.setUp();

        ScriptTypes.gAMPContracts memory gampContracts = DeploygAMPScript(address(new DeploygAMPScript().setUp()))
            .runAs(deployer);

        gamp = gampContracts.gamp;
    }

    function testCannotMintgAMPWithoutAmplifier() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        assertEq(gamp.balanceOf(userOne), 0);

        vm.startPrank(userOne);
        uint256 mintFee = gamp.mintFee();
        vm.expectRevert(bytes("Invalid ownership"));
        gamp.mint{value: mintFee}(ids);
        vm.stopPrank();

        assertEq(gamp.balanceOf(userOne), 0);
    }

    function testCannotMintgAMPExpiredAmplifier() public {
        testUtil.be(userOne).buyAmplifi();

        uint256 amplifierId = testUtil.createAmplifier(userOne, 1);

        testUtil.fuseAmplifier(userOne, amplifierId, Types.FuseProduct.OneYear);

        skip(31 days);

        uint256[] memory ids = new uint256[](1);
        ids[0] = amplifierId;

        assertEq(gamp.balanceOf(userOne), 0);

        vm.startPrank(userOne);
        uint256 mintFee = gamp.mintFee();
        vm.expectRevert(bytes("Amplifier expired"));
        gamp.mint{value: mintFee}(ids);
        vm.stopPrank();

        assertEq(gamp.balanceOf(userOne), 0);
    }

    function testCannotMintgAMPUnfusedAmplifier() public {
        testUtil.be(userOne).buyAmplifi();

        uint256 amplifierId = testUtil.createAmplifier(userOne, 1);

        skip(1 days);

        uint256[] memory ids = new uint256[](1);
        ids[0] = amplifierId;

        assertEq(gamp.balanceOf(userOne), 0);

        vm.startPrank(userOne);
        uint256 mintFee = gamp.mintFee();
        vm.expectRevert(bytes("Must be fused"));
        gamp.mint{value: mintFee}(ids);
        vm.stopPrank();

        assertEq(gamp.balanceOf(userOne), 0);
    }

    function testCannotMintgAMPIncorrectValue() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        assertEq(gamp.balanceOf(userOne), 0);

        vm.startPrank(userOne);
        vm.expectRevert(bytes("Invalid Ether value provided"));
        gamp.mint{value: 1}(ids);
        vm.stopPrank();

        assertEq(gamp.balanceOf(userOne), 0);
    }

    function testCanMintgAMP() public {
        testUtil.be(userOne).buyAmplifi();

        uint256 amplifierId = testUtil.createAmplifier(userOne, 1);

        testUtil.fuseAmplifier(userOne, amplifierId, Types.FuseProduct.OneYear);

        skip(1 days);

        uint256[] memory ids = new uint256[](1);
        ids[0] = amplifierId;

        assertEq(gamp.balanceOf(userOne), 0);

        vm.startPrank(userOne);
        gamp.mint{value: gamp.mintFee()}(ids);
        vm.stopPrank();

        assertGt(gamp.balanceOf(userOne), 0);
        assertEq(
            gamp.balanceOf(userOne),
            (gamp.totalAmountToMintPerProduct(Types.FuseProduct.OneYear) * 1 days) / 365 days
        );

        skip(1 days);
        vm.roll(block.number);

        vm.startPrank(userOne);
        gamp.mint{value: gamp.mintFee()}(ids);
        vm.stopPrank();

        assertApproxEqAbs(
            gamp.balanceOf(userOne),
            (gamp.totalAmountToMintPerProduct(Types.FuseProduct.OneYear) * 2 days) / 365 days,
            10
        );
    }

    function testCanMintMultiplegAMP() public {
        testUtil.be(userOne).buyAmplifi();

        uint256[] memory amplifierIds = testUtil.createAmplifierBatch(userOne, 1, 3);
        testUtil.fuseAmplifier(userOne, amplifierIds[0], Types.FuseProduct.OneYear);
        testUtil.fuseAmplifier(userOne, amplifierIds[1], Types.FuseProduct.ThreeYears);
        testUtil.fuseAmplifier(userOne, amplifierIds[2], Types.FuseProduct.FiveYears);

        skip(1 days);

        assertEq(gamp.balanceOf(userOne), 0);

        vm.startPrank(userOne);
        gamp.mint{value: gamp.mintFee() * 3}(amplifierIds);
        vm.stopPrank();

        assertGt(gamp.balanceOf(userOne), 0);
        assertEq(
            gamp.balanceOf(userOne),
            ((gamp.totalAmountToMintPerProduct(Types.FuseProduct.OneYear) * 1 days) / 365 days) +
                ((gamp.totalAmountToMintPerProduct(Types.FuseProduct.ThreeYears) * 1 days) / (365 days * 3)) +
                ((gamp.totalAmountToMintPerProduct(Types.FuseProduct.FiveYears) * 1 days) / (365 days * 5))
        );
    }

    function testCannotClaimETHWithIncorrectBlockNumber() public {
        testCanMintgAMP();

        uint256 gampBalance = address(gamp).balance;

        // Do some trading to gather fees
        for (uint256 i = 0; i < 40; i++) {
            address user = randomUsers[i % 20];

            uint256 balancePrev = amplifi.balanceOf(user);
            testUtil.be(user).buyAmplifi();
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            testUtil.sellAmplifi(user);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(address(gamp).balance, gampBalance);
        assertEq(address(gamp).balance, gamp.receivedThisPeriod());

        gampBalance = address(gamp).balance;

        skip(10 days);
        vm.roll(block.number + (10 days / 15));

        gamp.pot();

        assertEq(0, gamp.receivedThisPeriod());

        vm.roll(block.number + 1);

        uint256[] memory blockNumbers = new uint256[](1);
        blockNumbers[0] = block.number - 2;

        uint256 balanceBefore = userOne.balance;
        vm.startPrank(userOne);
        vm.expectRevert("No ETH claimable");
        gamp.claim(blockNumbers);
        vm.stopPrank();

        assertEq(userOne.balance, balanceBefore);
    }

    function testTeamCanClaimETH() public {
        uint256 gampBalance = address(gamp).balance;

        // Do some trading to gather fees
        for (uint256 i = 0; i < 40; i++) {
            address user = randomUsers[i % 20];

            uint256 balancePrev = amplifi.balanceOf(user);
            testUtil.be(user).buyAmplifi();
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            testUtil.sellAmplifi(user);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(address(gamp).balance, gampBalance);
        assertEq(address(gamp).balance, gamp.receivedThisPeriod());

        gampBalance = address(gamp).balance;

        vm.expectRevert("Cannot make a new pot too soon");
        gamp.pot();

        skip(5 days);
        vm.roll(block.number + (5 days / 15));

        vm.expectEmit(true, true, true, true, address(gamp));
        emit PotAccrued(gamp.receivedThisPeriod());
        gamp.pot();

        assertEq(0, gamp.receivedThisPeriod());

        vm.roll(block.number + 1);

        uint256[] memory blockNumbers = new uint256[](1);
        blockNumbers[0] = block.number - 1;

        vm.startPrank(gAMPTeamWallet);
        vm.expectRevert("Team addresses cannot claim");
        gamp.claim(blockNumbers);
        vm.stopPrank();

        vm.startPrank(gAMPDevWallet);
        vm.expectRevert("Team addresses cannot claim");
        gamp.claim(blockNumbers);
        vm.stopPrank();
    }

    function testCanClaimETH() public {
        testCanMintgAMP();

        uint256 gampBalance = address(gamp).balance;

        // Do some trading to gather fees
        for (uint256 i = 0; i < 40; i++) {
            address user = randomUsers[i % 20];

            uint256 balancePrev = amplifi.balanceOf(user);
            testUtil.be(user).buyAmplifi();
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            testUtil.sellAmplifi(user);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(address(gamp).balance, gampBalance);
        assertEq(address(gamp).balance, gamp.receivedThisPeriod());

        gampBalance = address(gamp).balance;

        vm.expectRevert("Cannot make a new pot too soon");
        gamp.pot();

        skip(5 days);
        vm.roll(block.number + (5 days / 15));

        vm.expectEmit(true, true, true, true, address(gamp));
        emit PotAccrued(gamp.receivedThisPeriod());
        gamp.pot();

        assertEq(0, gamp.receivedThisPeriod());

        vm.roll(block.number + 1);

        uint256[] memory blockNumbers = new uint256[](1);
        blockNumbers[0] = block.number - 1;

        assertEq(gamp.potPerPeriod(block.number - 1), gampBalance);

        uint256 balanceBefore = userOne.balance;
        vm.startPrank(userOne);
        vm.expectEmit(true, true, true, true, address(gamp));
        emit Claimed(userOne, block.number - 1, gamp.getClaimAmount(block.number - 1));
        gamp.claim(blockNumbers);

        uint256 claimAmount = gamp.getClaimAmount(block.number - 1);
        uint256 gainedAfterFee = claimAmount - ((claimAmount * gamp.claimFee()) / gamp.bps());

        assertGt(userOne.balance, balanceBefore);
        assertEq(userOne.balance, balanceBefore + gainedAfterFee);

        uint256 gainedViaDiffCalculation = ((gampBalance * gamp.balanceOf(userOne)) /
                    (gamp.totalSupply() - gamp.balanceOf(gAMPTeamWallet) - gamp.balanceOf(gAMPDevWallet)));

        gainedAfterFee = gainedViaDiffCalculation - ((gainedViaDiffCalculation * gamp.claimFee()) / gamp.bps());
        assertEq(userOne.balance, balanceBefore + gainedAfterFee);

        vm.stopPrank();
    }

    function testCanClaimETHAgain() public {
        testCanClaimETH();

        uint256 gampBalance = address(gamp).balance;

        // Do some trading to gather fees
        for (uint256 i = 0; i < 40; i++) {
            address user = randomUsers[i % 20];

            uint256 balancePrev = amplifi.balanceOf(user);
            testUtil.be(user).buyAmplifi();
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            testUtil.sellAmplifi(user);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(address(gamp).balance, gampBalance);

        gampBalance = gamp.receivedThisPeriod();

        skip(30 days);
        vm.roll(block.number + (30 days / 15));

        gamp.pot();

        assertEq(0, gamp.receivedThisPeriod());

        vm.roll(block.number + 1);

        uint256[] memory blockNumbers = new uint256[](1);
        blockNumbers[0] = block.number - 1;

        uint256 balanceBefore = userOne.balance;
        vm.startPrank(userOne);
        gamp.claim(blockNumbers);

        uint256 claimAmount = gamp.getClaimAmount(block.number - 1);
        uint256 gainedAfterFee = claimAmount - ((claimAmount * gamp.claimFee()) / gamp.bps());

        assertGt(userOne.balance, balanceBefore);
        assertEq(userOne.balance, balanceBefore + gainedAfterFee);

        vm.stopPrank();
    }

    function testCanClaimETHMultipleClaims() public {
        testCanMintgAMP();

        uint256 gampBalance = address(gamp).balance;

        // Do some trading to gather fees
        for (uint256 i = 0; i < 40; i++) {
            address user = randomUsers[i % 20];

            uint256 balancePrev = amplifi.balanceOf(user);
            testUtil.be(user).buyAmplifi();
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            testUtil.sellAmplifi(user);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(address(gamp).balance, gampBalance);
        assertEq(address(gamp).balance, gamp.receivedThisPeriod());

        gampBalance = address(gamp).balance;

        vm.expectRevert("Cannot make a new pot too soon");
        gamp.pot();

        skip(5 days);
        vm.roll(block.number + (5 days / 15));

        uint256[] memory blockNumbers = new uint256[](2);

        vm.expectEmit(true, true, true, true, address(gamp));
        emit PotAccrued(gamp.receivedThisPeriod());
        gamp.pot();

        vm.roll(block.number + 1);

        blockNumbers[0] = block.number - 1;

        assertEq(0, gamp.receivedThisPeriod());

        // Do some trading to gather fees
        for (uint256 i = 0; i < 40; i++) {
            address user = randomUsers[i % 20];

            uint256 balancePrev = amplifi.balanceOf(user);
            testUtil.be(user).buyAmplifi();
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            testUtil.sellAmplifi(user);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(address(gamp).balance, gampBalance);

        gampBalance = address(gamp).balance;

        skip(30 days);
        vm.roll(block.number + (30 days / 15));

        vm.expectEmit(true, true, true, true, address(gamp));
        emit PotAccrued(gamp.receivedThisPeriod());
        gamp.pot();

        vm.roll(block.number + 1);

        blockNumbers[1] = block.number - 1;

        assertEq(0, gamp.receivedThisPeriod());

        uint256 balanceBefore = userOne.balance;
        vm.startPrank(userOne);
        vm.expectEmit(true, true, true, true, address(gamp));
        emit Claimed(userOne, blockNumbers[0], gamp.getClaimAmount(blockNumbers[0]));
        vm.expectEmit(true, true, true, true, address(gamp));
        emit Claimed(userOne, blockNumbers[1], gamp.getClaimAmount(blockNumbers[1]));
        gamp.claim(blockNumbers);


        uint256 claimAmount = gamp.getClaimAmount(blockNumbers[0]) + gamp.getClaimAmount(blockNumbers[1]);
        uint256 gainedAfterFee = claimAmount - ((claimAmount * gamp.claimFee()) / gamp.bps());

        assertGt(userOne.balance, balanceBefore);
        assertEq(userOne.balance, balanceBefore + gainedAfterFee);

        vm.stopPrank();
    }

    function testCanClaimETHManyUsers() public {
        uint256 claimFeeRecipientBalanceBefore = gamp.claimFeeRecipient().balance;
        uint256 mintFeeRecipientBalanceBefore = gamp.mintFeeRecipient().balance;

        // userOne setup
        testUtil.be(userOne).buyAmplifi();
        uint256[] memory amplifierIds1 = testUtil.createAmplifierBatch(userOne, 1, 1);
        testUtil.fuseAmplifier(userOne, amplifierIds1[0], Types.FuseProduct.OneYear);

        // userTwo setup
        testUtil.be(userTwo).buyAmplifi();
        uint256[] memory amplifierIds2 = testUtil.createAmplifierBatch(userTwo, 1, 1);
        testUtil.fuseAmplifier(userTwo, amplifierIds2[0], Types.FuseProduct.OneYear);

        skip(1 days);

        assertEq(gamp.balanceOf(userOne), 0);
        assertEq(gamp.balanceOf(userTwo), 0);

        // mint gAMP for both users
        vm.startPrank(userOne);
        gamp.mint{value: gamp.mintFee()}(amplifierIds1);
        vm.stopPrank();

        assertGt(gamp.balanceOf(userOne), 0);

        vm.startPrank(userTwo);
        gamp.mint{value: gamp.mintFee()}(amplifierIds2);
        vm.stopPrank();

        assertGt(gamp.balanceOf(userTwo), 0);

        uint256 gampBalance = address(gamp).balance;

        // Do some trading to gather fees
        for (uint256 i = 0; i < 40; i++) {
            address user = randomUsers[i % 20];

            uint256 balancePrev = amplifi.balanceOf(user);
            testUtil.be(user).buyAmplifi();
            assertGt(amplifi.balanceOf(user), balancePrev);

            uint256 ethBalancePrev = user.balance;
            testUtil.sellAmplifi(user);
            assertGt(user.balance, ethBalancePrev);
        }

        assertGt(address(gamp).balance, gampBalance);
        assertEq(address(gamp).balance, gamp.receivedThisPeriod());

        gampBalance = address(gamp).balance;

        // Set the pot
        skip(5 days);
        vm.roll(block.number + (5 days / 15));

        gamp.pot();

        vm.roll(block.number + 1);

        uint256[] memory blockNumbers = new uint256[](1);
        blockNumbers[0] = block.number - 1;

        // Claim for userOne
        uint256 balanceBefore = userOne.balance;
        vm.startPrank(userOne);
        gamp.claim(blockNumbers);

        uint256 claimAmount = gamp.getClaimAmount(block.number - 1);
        uint256 gainedAfterFee = claimAmount - ((claimAmount * gamp.claimFee()) / gamp.bps());

        assertGt(userOne.balance, balanceBefore);
        assertEq(userOne.balance, balanceBefore + gainedAfterFee);

        vm.stopPrank();

        // Claim for userTwo
        balanceBefore = userTwo.balance;
        vm.startPrank(userTwo);
        gamp.claim(blockNumbers);

        claimAmount = gamp.getClaimAmount(block.number - 1);
        gainedAfterFee = claimAmount - ((claimAmount * gamp.claimFee()) / gamp.bps());

        assertGt(userTwo.balance, balanceBefore);
        assertEq(userTwo.balance, balanceBefore + gainedAfterFee);

        vm.stopPrank();

        assertGt(gamp.claimFeeRecipient().balance, claimFeeRecipientBalanceBefore);
        assertGt(gamp.mintFeeRecipient().balance, mintFeeRecipientBalanceBefore);
    }

    function testCannotClaimETHTwice() public {
        testCanClaimETH();

        uint256 balanceBefore = userOne.balance;

        vm.roll(block.number + 1);

        uint256[] memory blockNumbers = new uint256[](1);
        blockNumbers[0] = block.number - 2;

        balanceBefore = userOne.balance;
        vm.startPrank(userOne);
        vm.expectRevert("Already claimied this period");
        gamp.claim(blockNumbers);
        vm.stopPrank();

        assertEq(userOne.balance, balanceBefore);
    }
}
