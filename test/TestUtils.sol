// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi} from "../src/Amplifi.sol";
import {AmplifiNode} from "../src/AmplifiNode.sol";
import {Types} from "../src/Types.sol";

using testUtils for TestUtils global;

struct TestUtils {
    Vm vm;
    Amplifi amplifi;
    address user;
}

library testUtils {
    function on(TestUtils storage _setup, Vm _vm) internal returns (TestUtils storage) {
        _setup.vm = _vm;
        return _setup;
    }

    function with(TestUtils storage _setup, Amplifi _amplifi) internal returns (TestUtils storage) {
        _setup.amplifi = _amplifi;
        return _setup;
    }

    function be(TestUtils storage _setup, address _user) internal returns (TestUtils storage) {
        _setup.user = _user;
        return _setup;
    }


    function buyAmplifi(TestUtils storage _setup) internal {
        Vm vm = _setup.vm;
        Amplifi amplifi = _setup.amplifi;
        address user = _setup.user;

        address[] memory path = new address[](3);
        path[0] = address(amplifi.WETH());
        path[1] = address(amplifi.USDC());
        path[2] = address(amplifi);

        uint256 toBuy = user.balance / 2;
        if(toBuy > 10 ether) {
            toBuy = 10 ether;
        }

        vm.startPrank(user);

        amplifi.router().swapExactETHForTokensSupportingFeeOnTransferTokens{value: toBuy}(
            0,
            path,
            user,
            block.timestamp
        );

        vm.stopPrank();
    }

    function sellAmplifi(TestUtils storage _setup, address _user) internal {
        Vm vm = _setup.vm;
        Amplifi amplifi = _setup.amplifi;

        address[] memory path = new address[](3);
        path[0] = address(amplifi);
        path[1] = address(amplifi.USDC());
        path[2] = address(amplifi.WETH());

        uint256 toSell = amplifi.balanceOf(_user) / 2;
        if(toSell > 50 ether) {
            toSell = 50 ether;
        }

        vm.startPrank(_user);

        amplifi.approve(address(amplifi.router()), type(uint256).max);

        amplifi.router().swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSell,
            0,
            path,
            _user,
            block.timestamp
        );

        vm.stopPrank();
    }

    function createAmplifier(
        TestUtils storage _setup,
        address _user,
        uint256 _months
    ) internal returns (uint256 id) {
        Vm vm = _setup.vm;
        Amplifi amplifi = _setup.amplifi;
        AmplifiNode amplifiNode = amplifi.amplifiNode();

        vm.startPrank(_user);

        amplifi.approve(address(amplifiNode), type(uint256).max);
        id = amplifiNode.createAmplifier{value: amplifiNode.renewalFee() * _months + amplifiNode.creationFee()}(
            _months
        );

        vm.stopPrank();
    }

    function createAmplifierBatch(
        TestUtils storage _setup,
        address _user,
        uint256 _months,
        uint256 _amount
    ) internal returns (uint256[] memory ids) {
        Vm vm = _setup.vm;
        Amplifi amplifi = _setup.amplifi;
        AmplifiNode amplifiNode = amplifi.amplifiNode();

        vm.startPrank(_user);

        amplifi.approve(address(amplifiNode), type(uint256).max);
        ids = amplifiNode.createAmplifierBatch{value: ((amplifiNode.renewalFee() * _months) + amplifiNode.creationFee()) * _amount}(
            _amount, _months
        );

        vm.stopPrank();
    }

    function fuseAmplifier(
        TestUtils storage _setup,
        address _user,
        uint256 _id,
        Types.FuseProduct _fuseProduct
    ) internal {
        Vm vm = _setup.vm;
        Amplifi amplifi = _setup.amplifi;
        AmplifiNode amplifiNode = amplifi.amplifiNode();

        vm.startPrank(_user);

        amplifiNode.fuseAmplifier{value: amplifiNode.fuseFee()}(_id, _fuseProduct);

        vm.stopPrank();
    }
}
