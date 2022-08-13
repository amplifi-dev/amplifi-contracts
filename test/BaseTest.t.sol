// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Solenv} from "solenv/Solenv.sol";

import {Amplifi, AmplifiNode, IERC20, IUniswapV2Router02, Types} from "../src/Amplifi.sol";

import {DeployScript} from "../script/Deploy.s.sol";
import {EnableScript} from "../script/Enable.s.sol";

import {ScriptTypes} from "../script/ScriptTypes.sol";

contract BaseTest is Test {
    address immutable owner = address(0x4a5c98C184dA163cFffa7F1296c913135565ad3f);
    address immutable userOne = address(0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf);
    address immutable userTwo = address(0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8);
    address immutable userThree = address(0x0716a17FBAeE714f1E6aB0f9d59edbC5f09815C0);

    address[20] randomUsers = [
        address(0x8c8a6224f0605Abe0fC1E6F70928Af0fBb82d7c4),
        address(0x9727B3eFEB79aBD6B2149342ba4299F927bAcb1b),
        address(0x883268CAaEB74f0651570EC2D2599B20baB8dACe),
        address(0xe6Fe14a30631b22d3f78D9eC7869eB62d6e73dAA),
        address(0xDC10a541118A88Eabfe87cDa3F52f363112AaE1c),
        address(0x1F7fd08219956d9e06286c6AD296742121D2fEDf),
        address(0xe339c4462292A30132808A8184496C79e0BA7937),
        address(0x05e059A4020E9743C3262DdB01908159500F3b81),
        address(0x5a0BEA14Dbe2a56607eb242d0309047643884875),
        address(0xE11959A206fafFDB1cc410A94e3943E0Df47cBA8),
        address(0xB0764b8c275a9733160ec4FC5C76Bf313E8736d9),
        address(0x8A18a7ea34a476018DA24C385f07Dc2508A45c50),
        address(0x657EAC972dd08Ec75AA3BA246aE4D4884b0abEfc),
        address(0x16d8244a48039F2E199546401e19AA54476721E1),
        address(0xA44a6c72b629bB5CCD04A388AF4A99460Ca75B0e),
        address(0x253DFc0f440b9c81D49747484faEA8eb9Ed38AC7),
        address(0x5B0c80Aa42c8dDda3E0bd90c9eC0754465F109De),
        address(0x28d26A88Ed64D7150C8f05d24ce601845657Aa44),
        address(0x624D3fFF641F6B93724Bb96F59Fd306690C62ef2),
        address(0x12eeA318976af59F266B99B8f2245c3cdB8c5CC2)
    ];

    address immutable circle = address(0x55FE002aefF02F77364de339a1292923A15844B8);

    ScriptTypes.Contracts internal contracts;

    Amplifi internal amplifi;
    AmplifiNode internal amplifiNode;
    IUniswapV2Router02 internal router;
    IERC20 internal usdc;
    IERC20 internal weth;

    function setUp() public virtual {
        Solenv.config();
        vm.createSelectFork(vm.envString("MAIN_RPC_URL"));

        vm.deal(owner, 1000 ether);

        // deal(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, owner, 150_000e6);

        // Run Deploy script
        // DeployScript deployScript = new DeployScript();
        // contracts = deployScript.run();

        amplifi = Amplifi(payable(0xD23367155B55d67492DFDC0FC7f8bB1dF7114fD9));
        amplifiNode = amplifi.amplifiNode();
        router = amplifi.router();
        usdc = amplifi.USDC();
        weth = amplifi.WETH();
    }

    function runEnableScript() public {
        // Run Enable script
        EnableScript enableScript = new EnableScript();
        enableScript.run(amplifi);
    }
}
