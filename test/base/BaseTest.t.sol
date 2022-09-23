// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Amplifi, AmplifiNode, IERC20, IUniswapV2Router02, Types} from "../../src/Amplifi.sol";

import {DeployScript} from "../../script/Deploy.s.sol";
import {EnableScript} from "../../script/Enable.s.sol";

import {ScriptTypes} from "../../script/ScriptTypes.sol";

import {TestUtils} from "../TestUtils.sol";

abstract contract BaseTest is Test {
    address constant deployer = 0x4a5c98C184dA163cFffa7F1296c913135565ad3f;
    address constant userOne = 0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf;
    address constant userTwo = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;
    address constant userThree = 0x0716a17FBAeE714f1E6aB0f9d59edbC5f09815C0;

    address internal owner;

    address[20] randomUsers = [
        0x8c8a6224f0605Abe0fC1E6F70928Af0fBb82d7c4,
        0x9727B3eFEB79aBD6B2149342ba4299F927bAcb1b,
        0x742d35Cc6634C0532925a3b844Bc454e4438f44e,
        0xA7EFAe728D2936e78BDA97dc267687568dD593f3,
        0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94,
        0x9845e1909dCa337944a0272F1f9f7249833D2D19,
        0x0548F59fEE79f8832C299e01dCA5c76F034F558e,
        0xcA8Fa8f0b631EcdB18Cda619C4Fc9d197c8aFfCa,
        0x6a2C3C4C7169d69A67ae2251c7D765Ac79A4967e,
        0x8103683202aa8DA10536036EDef04CDd865C225E,
        0xB29380ffC20696729B7aB8D093fA1e2EC14dfe2b,
        0x0a4c79cE84202b03e95B7a692E5D728d83C44c76,
        0x25eAff5B179f209Cf186B1cdCbFa463A69Df4C45,
        0x2B6eD29A95753C3Ad948348e3e7b1A251080Ffb9,
        0x189B9cBd4AfF470aF2C0102f365FC1823d857965,
        0x9acb5CE4878144a74eEeDEda54c675AA59E0D3D2,
        0x176F3DAb24a159341c0509bB36B833E7fdd0a132,
        0x28d26A88Ed64D7150C8f05d24ce601845657Aa44,
        0x624D3fFF641F6B93724Bb96F59Fd306690C62ef2,
        0x12eeA318976af59F266B99B8f2245c3cdB8c5CC2
    ];

    address constant circle = 0x55FE002aefF02F77364de339a1292923A15844B8;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ScriptTypes.Contracts internal contracts;

    Amplifi internal amplifi;
    AmplifiNode internal amplifiNode;
    IUniswapV2Router02 internal router;
    IERC20 internal usdc;
    IERC20 internal weth;

    TestUtils internal testUtil;

    function setUp() public virtual {
        vm.createSelectFork("mainnet");
    }
}
