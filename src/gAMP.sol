// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswap.sol";

interface IVault {
    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;
}

contract Vault is IVault, Ownable {
    uint256 internal constant max = 2**256 - 1;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // weth
    IERC20 BASE = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Router02 router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => uint256) public totalRewardsDistributed;
    mapping(address => mapping(address => uint256)) public totalRewardsToUser;

    mapping(address => bool) public availableRewards;
    mapping(address => address) public pathRewards;

    mapping(address => bool) public allowed;
    mapping(address => address) public choice;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router, address _owner) {
        transferOwnership(_owner);
        router = _router != address(0)
            ? IUniswapV2Router02(_router)
            : IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;

        // weth
        allowed[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true;
        // usdt
        allowed[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true;
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function setReward(address _reward, bool status) public onlyOwner {
        availableRewards[_reward] = status;
    }

    function setPathReward(address _reward, address _path) public onlyOwner {
        pathRewards[_reward] = _path;
    }

    function getPathReward(address _reward) public view returns (address) {
        return pathRewards[_reward];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder, address(BASE));
        }
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }
        totalShares = totalShares - (shares[shareholder].amount) + (amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        totalDividends = totalDividends + msg.value;
        dividendsPerShare = dividendsPerShare + ((dividendsPerShareAccuracyFactor * msg.value) / (totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + (amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + (amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress] + (amount);
                totalRewardsToUser[rewardAddress][shareholder] =
                    totalRewardsToUser[rewardAddress][shareholder] +
                    (amount);
            } else {
                IERC20 rewardToken = IERC20(rewardAddress);
                uint256 beforeBalance = rewardToken.balanceOf(shareholder);
                if (pathRewards[rewardAddress] == address(0)) {
                    address[] memory path = new address[](2);
                    path[0] = address(BASE);
                    path[1] = rewardAddress;
                    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                        0,
                        path,
                        shareholder,
                        block.timestamp
                    );
                } else {
                    address[] memory path = new address[](3);
                    path[0] = address(BASE);
                    path[1] = pathRewards[rewardAddress];
                    path[2] = rewardAddress;
                    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                        0,
                        path,
                        shareholder,
                        block.timestamp
                    );
                }
                uint256 afterBalance = rewardToken.balanceOf(shareholder);
                totalRewardsDistributed[rewardAddress] =
                    totalRewardsDistributed[rewardAddress] +
                    (afterBalance - (beforeBalance));
                totalRewardsToUser[rewardAddress][shareholder] =
                    totalRewardsToUser[rewardAddress][shareholder] +
                    (afterBalance - (beforeBalance));
            }
        }
    }

    function claimDividend(address rewardAddress) external {
        distributeDividend(msg.sender, rewardAddress);
    }

    function toggleChoice(address _choice) public onlyOwner {
        allowed[_choice] = !allowed[_choice];
    }

    function getChoice(address _choice) public view returns (bool) {
        return allowed[_choice];
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }
        return shareholderTotalDividends - (shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return (share * (dividendsPerShare)) / (dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function changeBASE(address _BASE) external onlyOwner {
        BASE = IERC20(_BASE);
    }

    function rescueETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueERC(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

contract gAMP is ERC20, Ownable {
    IVault public vault;

    constructor(address _router) ERC20("gAMP", "gAMP") {
        vault = new Vault(_router, msg.sender);

        _mint(msg.sender, 10_000e18);
    }

    function sendToOpWallet() external payable {
        if (msg.value > 0) {
            vault.deposit{value: msg.value}();
        }
    }

    function drainGas() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function drainToken(address _token, address _recipient) external onlyOwner {
        IERC20(_token).transfer(_recipient, IERC20(_token).balanceOf(address(this)));
    }

    receive() external payable {}
}
