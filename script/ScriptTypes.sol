// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Amplifi} from "../src/Amplifi.sol";
import {FeeSplitter} from "../src/FeeSplitter.sol";
import {gAMP} from "../src/gAMP.sol";
import {ERC20StakingPool} from "../src/ERC20StakingPool.sol";

library ScriptTypes {
    struct Contracts {
        Amplifi amplifi;
    }

    struct FeeSplitterContracts {
        FeeSplitter feeSplitter;
    }

    struct gAMPContracts {
        gAMP gamp;
    }

    struct StakingContracts {
        ERC20StakingPool singleStakingPool;
        ERC20StakingPool lpStakingPool;
    }
}
