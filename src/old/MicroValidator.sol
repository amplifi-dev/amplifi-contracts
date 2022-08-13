// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./other.sol";

contract MicroValidator is AC, ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public microvAddress;
    IERC20 microv;
    Network1 private _network1;
    address public network1Address;
    Network2 private _network2;
    address public network2Address;
    Network3 private _network3;
    address public network3Address;
    Network4 private _network4;
    address public network4Address;
    address public renewals = 0xa1ed930901534A5eecCC37fE131362e3054c4a82;
    address public claims = 0xa1ed930901534A5eecCC37fE131362e3054c4a82;
    address public rewards = 0x000000000000000000000000000000000000dEaD;
    address public liquidity = 0x4D939977da7D0d0C3239dd0415F13a35cC1664b4;
    address public reserves = 0xa1ed930901534A5eecCC37fE131362e3054c4a82;
    address public partnerships = 0xFf20C9736ac252014800782692d867B4C70656d1;
    address public dead = 0x000000000000000000000000000000000000dEaD;
    uint256 public rate0 = 700000000000;
    uint256[20] public rates0 = [700000000000, 595000000000, 505750000000, 429887500000, 365404375000, 310593718750, 264004660937, 224403961797, 190743367527, 162131862398, 137812083039, 117140270583, 99569229995, 84633845496, 71938768672, 61147953371, 51975760365, 44179396311, 37552486864, 31919613834];
    uint256 public amount1 = 21759840000000000000;
    uint256 public amount2 = 135999000000000000000;
    uint256 public amount3 = 326397600000000000000;
    uint256 public amount4 = 658017561600000000000;
    uint256 public seconds1 = 31536000;
    uint256 public seconds2 = 94608000;
    uint256 public seconds3 = 157680000;
    uint256 public seconds4 = 504576000;
    uint256 public gracePeriod = 2628000;
    uint256 public gammaPeriod = 5443200;
    uint256 public quarter = 7884000;
    uint256 public month = 2628000;
    uint256 public maxValidatorsPerMinter = 100;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    struct Validator {
        uint256 id;
        address minter;
        uint256 created;
        uint256 lastClaimMicrov;
        uint256 lastClaimEth;
        uint256 numClaimsMicrov;
        uint256 renewalExpiry;
        uint8 fuseProduct;
        uint256 fuseCreated;
        uint256 fuseUnlocks;
        bool fuseUnlocked;
    }
    mapping (uint256 => Validator) public validators;
    mapping (address => Validator[]) public validatorsByMinter;
    mapping (address => uint256) public numValidatorsByMinter;
    mapping (uint256 => uint256) public positions;
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    uint256 public renewalFee = 1000 * 1000000;
    uint256 public claimMicrovFee = 6900 * 1000000;
    uint256 public claimEthFee = 639 * 1000000;
    uint256 public mintPrice = 10 * (10 ** 18);
    uint256 public rewardsFee = 6 * (10 ** 18);
    uint256 public liquidityFee = 10 ** 18;
    uint256 public reservesFee = 10 ** 18;
    uint256 public partnershipsFee = 10 ** 18;
    uint256 public deadFee = 10 ** 18;

    constructor(string memory _name, string memory _symbol, address _microvAddress, address _owner, address _priceFeed, address _weth) ERC721(_name, _symbol, _owner) {
        rewards = address(this);
        microvAddress = _microvAddress;
        microv = IERC20(microvAddress);
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _network1 = new Network1(_router, _owner, _weth);
        network1Address = address(_network1);
        _network2 = new Network2(_router, _owner, _weth);
        network2Address = address(_network2);
        _network3 = new Network3(_router, _owner, _weth);
        network3Address = address(_network3);
        _network4 = new Network4(_router, _owner, _weth);
        network4Address = address(_network4);
        priceFeed = AggregatorV3Interface(_priceFeed);
        weth = _weth;
    }

    function createToken(uint256 _months) external payable nonReentrant returns (uint) {
        require(numValidatorsByMinter[msg.sender] < maxValidatorsPerMinter, "Too many validators");
        require(_months < 193, "Too many months");
        require(msg.value == getRenewalCost(_months), "Invalid value");
        require(microv.allowance(msg.sender, address(this)) > mintPrice, "Insufficient allowance");
        require(microv.balanceOf(msg.sender) > mintPrice, "Insufficient balance");
        bool _success = microv.transferFrom(msg.sender, address(this), mintPrice);
        require(_success, "Transfer unsuccessful");
        payable(renewals).transfer(msg.value);
        microv.transfer(rewards, rewardsFee);
        microv.transfer(liquidity, liquidityFee);
        microv.transfer(reserves, reservesFee);
        microv.transfer(partnerships, partnershipsFee);
        microv.transfer(dead, deadFee);
        uint256 _newItemId = _tokenIds.current();
        _tokenIds.increment();
        _mint(msg.sender, _newItemId);
        _setTokenURI(_newItemId, string(abi.encodePacked(_newItemId, ".json")));
        Validator memory _validator = Validator(_newItemId, msg.sender, block.timestamp, 0, 0, 0, block.timestamp + (2628000 * _months), 0, 0, 0, false);
        validators[_newItemId] = _validator;
        validatorsByMinter[msg.sender].push(_validator);
        positions[_newItemId] = numValidatorsByMinter[msg.sender];
        numValidatorsByMinter[msg.sender]++;
        return _newItemId;
    }

    function fuseToken(uint256 _id, uint8 _tier) external nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        require(_tier == 1 || _tier == 2 || _tier == 3 || _tier == 4, "Invalid product");
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 0 || _validator.fuseUnlocked, "Already fused");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        uint256 _seconds = seconds1;
        uint256 _balance = 0;
        uint256 _matches = numValidatorsByMinter[msg.sender];
        Validator[] memory _array = validatorsByMinter[msg.sender];
        for (uint256 _i = 0; _i < _matches; _i++) {
            Validator memory _v = _array[_i];
            if (_v.fuseProduct == _tier && !_v.fuseUnlocked && _v.renewalExpiry > block.timestamp && _v.fuseUnlocks < block.timestamp) _balance++;
        }
        if (_tier == 1) {
            try _network1.setShare(msg.sender, _balance + 1) {} catch {}
        } else if (_tier == 2) {
            try _network2.setShare(msg.sender, _balance + 1) {} catch {}
            _seconds = seconds2;
        } else if (_tier == 3) {
            try _network3.setShare(msg.sender, _balance + 1) {} catch {}
            _seconds = seconds3;
        } else if (_tier == 4) {
            try _network4.setShare(msg.sender, _balance + 1) {} catch {}
            _seconds = seconds4;
        }
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, 0, _validator.numClaimsMicrov, _validator.renewalExpiry, _tier, block.timestamp, block.timestamp + _seconds, false);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function renewToken(uint256 _id, uint256 _months) external payable nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        require(_months < 193, "Too many months");
        uint256 _boost = 2628000 * _months;
        require(msg.value == getRenewalCost(_months), "Invalid value");
        Validator memory _validator = validators[_id];
        require(_validator.renewalExpiry + gracePeriod > block.timestamp, "Grace period expired");
        if (_validator.fuseProduct > 0) {
            require(!_validator.fuseUnlocked, "Must be unlocked");
            require(_validator.renewalExpiry + _boost <= _validator.fuseUnlocks + gracePeriod, "Renewing too far");
        }
        payable(renewals).transfer(msg.value);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, _validator.lastClaimEth, _validator.numClaimsMicrov, _validator.renewalExpiry + _boost, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, false);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function claimMicrov(uint256 _id) external payable nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        Validator memory _validator = validators[_id];
        uint8 _fuseProduct = _validator.fuseProduct;
        require(_fuseProduct == 0, "Must be fused");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        require(msg.value == getClaimMicrovCost(), "Invalid value");
        payable(claims).transfer(msg.value);
        (, uint256 _amount) = getPendingMicrov(_id);
        microv.transfer(msg.sender, _amount);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, block.timestamp, _validator.lastClaimEth, _validator.numClaimsMicrov + 1, _validator.renewalExpiry, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, _validator.fuseUnlocked);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function claimEth(uint256 _id) external payable nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 1 || _validator.fuseProduct == 2 || _validator.fuseProduct == 3 || _validator.fuseProduct == 4, "Invalid product");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        require(!_validator.fuseUnlocked, "Already unlocked");
        if (_validator.lastClaimEth == 0) {
            require(_validator.lastClaimEth >= _validator.fuseCreated + quarter, "Too early");
        } else {
            require(_validator.lastClaimEth >= _validator.lastClaimEth + month, "Too early");
        }
        require(msg.value == getClaimEthCost(), "Invalid value");
        payable(claims).transfer(msg.value);
        _refresh(msg.sender, true, _validator.fuseProduct);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, block.timestamp, _validator.numClaimsMicrov, _validator.renewalExpiry, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, _validator.fuseUnlocked);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function _refresh(address _address, bool _claim, uint8 _tier) private {
        uint256 _1balance = 0;
        uint256 _2balance = 0;
        uint256 _3balance = 0;
        uint256 _4balance = 0;
        uint256 _matches = numValidatorsByMinter[_address];
        Validator[] memory _array = validatorsByMinter[_address];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].fuseProduct > 0 && !_array[_i].fuseUnlocked && _array[_i].renewalExpiry > block.timestamp && _array[_i].fuseUnlocks < block.timestamp) {
                uint256 _fuseProduct = _array[_i].fuseProduct;
                if (_fuseProduct == 1) _1balance++;
                else if (_fuseProduct == 2) _2balance++;
                else if (_fuseProduct == 3) _3balance++;
                else if (_fuseProduct == 4) _4balance++;
            }
        }
        if (_claim) {
            if (_tier == 1) try _network1.claimDividend(_address, weth) {} catch {}
            else if (_tier == 2) try _network2.claimDividend(_address, weth) {} catch {}
            else if (_tier == 3) try _network3.claimDividend(_address, weth) {} catch {}
            else if (_tier == 4) try _network4.claimDividend(_address, weth) {} catch {}
        }
        try _network1.setShare(_address, _1balance) {} catch {}
        try _network2.setShare(_address, _2balance) {} catch {}
        try _network3.setShare(_address, _3balance) {} catch {}
        try _network4.setShare(_address, _4balance) {} catch {}
    }

    function unlockMicrov(uint256 _id) external nonReentrant {
        require(ownerOf(_id) == msg.sender, "Invalid ownership");
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 1 || _validator.fuseProduct == 2 || _validator.fuseProduct == 3 || _validator.fuseProduct == 4, "Invalid product");
        require(_validator.renewalExpiry > block.timestamp, "Expired");
        require(_validator.fuseUnlocks >= block.timestamp, "Too early");
        require(!_validator.fuseUnlocked, "Already unlocked");
        _refresh(msg.sender, true, _validator.fuseProduct);
        if (_validator.fuseProduct == 1) microv.transfer(msg.sender, amount1);
        else if (_validator.fuseProduct == 2) microv.transfer(msg.sender, amount2);
        else if (_validator.fuseProduct == 3) microv.transfer(msg.sender, amount3);
        else if (_validator.fuseProduct == 4) microv.transfer(msg.sender, amount4);
        Validator memory _validatorNew = Validator(_id, _validator.minter, _validator.created, _validator.lastClaimMicrov, _validator.lastClaimEth, _validator.numClaimsMicrov, _validator.renewalExpiry, _validator.fuseProduct, _validator.fuseCreated, _validator.fuseUnlocks, true);
        validators[_id] = _validatorNew;
        validatorsByMinter[msg.sender][positions[_id]] = _validatorNew;
    }

    function slash(uint256 _id) external nonReentrant onlyOwner {
        Validator memory _validator = validators[_id];
        require(_validator.fuseProduct == 1 || _validator.fuseProduct == 2 || _validator.fuseProduct == 3 || _validator.fuseProduct == 4, "Invalid product");
        require(_validator.renewalExpiry + gracePeriod <= block.timestamp, "Not expired");
        _refresh(_validator.minter, false, 0);
    }

    function changeRatesAmounts(uint256 _rate0, uint256 _amount1, uint256 _amount2, uint256 _amount3, uint256 _amount4) external nonReentrant onlyOwner {
        rate0 = _rate0;
        amount1 = _amount1;
        amount2 = _amount2;
        amount3 = _amount3;
        amount4 = _amount4;
    }

    function configureMinting(uint256 _mintPrice, uint256 _rewardsFee, uint256 _liquidityFee, uint256 _reservesFee, uint256 _partnershipsFee, uint256 _deadFee) external nonReentrant onlyOwner {
        require(_mintPrice == _rewardsFee + _liquidityFee + _reservesFee + _partnershipsFee + _deadFee, "");
        mintPrice = _mintPrice;
        rewardsFee = _rewardsFee;
        liquidityFee = _liquidityFee;
        reservesFee = _reservesFee;
        partnershipsFee = _partnershipsFee;
        deadFee = _deadFee;
    }

    function changeRenewalFee(uint256 _renewalFee) external nonReentrant onlyOwner {
        renewalFee = _renewalFee;
    }

    function changeClaimMicrovFee(uint256 _claimMicrovFee) external nonReentrant onlyOwner {
        claimMicrovFee = _claimMicrovFee;
    }

    function changeClaimEthFee(uint256 _claimEthFee) external nonReentrant onlyOwner {
        claimEthFee = _claimEthFee;
    }

    function setGracePeriod(uint256 _gracePeriod) external nonReentrant onlyOwner {
        gracePeriod = _gracePeriod;
    }

    function setQuarter(uint256 _quarter) external nonReentrant onlyOwner {
        quarter = _quarter;
    }

    function setMonth(uint256 _month) external nonReentrant onlyOwner {
        month = _month;
    }

    function setMaxValidatorsPerMinter(uint256 _maxValidatorsPerMinter) external nonReentrant onlyOwner {
        maxValidatorsPerMinter = _maxValidatorsPerMinter;
    }

    function changeMicrov(address _microvAddress) external nonReentrant onlyOwner {
        microvAddress = _microvAddress;
        microv = IERC20(microvAddress);
    }

    function changeWeth(address _weth) external nonReentrant onlyOwner {
        weth = _weth;
    }

    function switchPriceFeed(address _priceFeed) external nonReentrant onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getNetworks() external view returns (address, address, address, address) {
        return (network1Address, network2Address, network3Address, network4Address);
    }

    function getGracePeriod() external view returns (uint256) {
        return gracePeriod;
    }

    function getQuarter() external view returns (uint256) {
        return quarter;
    }

    function getMaxValidatorsPerMinter() external view returns (uint256) {
        return maxValidatorsPerMinter;
    }

    function getClaimMicrovCost() public view returns (uint256) {
        return (claimMicrovFee * (10 ** 18)) / uint(getLatestPrice());
    }

    function getClaimEthCost() public view returns (uint256) {
        return (claimEthFee * (10 ** 18)) / uint(getLatestPrice());
    }

    function getRenewalCost(uint256 _months) public view returns (uint256) {
        return (renewalFee * (10 ** 18)) / uint(getLatestPrice()) * _months;
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 _price, , , ) = priceFeed.latestRoundData();
        return _price;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function getPendingMicrov(uint256 _id) public view returns (uint256, uint256) {
        Validator memory _validator = validators[_id];
        uint8 _fuseProduct = _validator.fuseProduct;
        require(_fuseProduct == 0, "Must be fused");
        uint256 _newRate = rates0[_validator.numClaimsMicrov];
        uint256 _amount = (block.timestamp - (_validator.numClaimsMicrov > 0 ? _validator.lastClaimMicrov : _validator.created)) * (_newRate);
        if (_validator.created < block.timestamp + gammaPeriod) {
            uint256 _seconds = (block.timestamp + gammaPeriod) - _validator.created;
            uint256 _percent = 100;
            if (_seconds >= 4838400) _percent = 900;
            else if (_seconds >= 4233600) _percent = 800;
            else if (_seconds >= 3628800) _percent = 700;
            else if (_seconds >= 3024000) _percent = 600;
            else if (_seconds >= 2419200) _percent = 500;
            else if (_seconds >= 1814400) _percent = 400;
            else if (_seconds >= 1209600) _percent = 300;
            else if (_seconds >= 604800) _percent = 200;
            uint256 _divisor = _amount * _percent;
            (bool _divisible, ) = tryDiv(_divisor, 10000);
            _amount = _amount - (_divisible ? (_divisor / 10000) : 0);
        }
        return (_newRate, _amount);
    }

    function setRecipients(address _renewals, address _claims, address _rewards, address _liquidity, address _reserves, address _partnerships, address _dead) external onlyOwner {
        renewals = _renewals;
        claims = _claims;
        rewards = _rewards;
        liquidity = _liquidity;
        reserves = _reserves;
        partnerships = _partnerships;
        dead = _dead;
    }

    function getValidator(uint256 _id) external view returns (Validator memory) {
        return validators[_id];
    }

    function getValidatorsByMinter(address _minter) external view returns (Validator[] memory) {
        return validatorsByMinter[_minter];
    }

    function getNumValidatorsByMinter(address _minter) external view returns (uint256) {
        return numValidatorsByMinter[_minter];
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _token, address _recipient) external onlyOwner {
        IERC20(_token).transfer(_recipient, IERC20(_token).balanceOf(address(this)));
    }

    function deposit1() external payable onlyOwner {
        if (msg.value > 0) {
            try _network1.deposit{value: msg.value}() {} catch {}
        }
    }

    function deposit2() external payable onlyOwner {
        if (msg.value > 0) {
            try _network2.deposit{value: msg.value}() {} catch {}
        }
    }

    function deposit3() external payable onlyOwner {
        if (msg.value > 0) {
            try _network3.deposit{value: msg.value}() {} catch {}
        }
    }

    function deposit4() external payable onlyOwner {
        if (msg.value > 0) {
            try _network4.deposit{value: msg.value}() {} catch {}
        }
    }

    receive() external payable {}
}