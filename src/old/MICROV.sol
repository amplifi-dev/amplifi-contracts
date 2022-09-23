// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./other.sol";
import "./MicroValidator.sol";

contract MICROV is IERC20, AC {
    using SafeMath for uint256;
    address public BASE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    string private constant _name = "MicroValidator";
    string private constant _symbol = "MICROV";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 1000000 * (10**_decimals);
    uint256 public maxWallet = _totalSupply;
    uint256 public minAmountToTriggerSwap = 0;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isDisabledExempt;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isMaxExempt;
    mapping(address => bool) public isUniswapPair;
    uint256 public buyFeeOp = 300;
    uint256 public buyFeeValidator = 0;
    uint256 public buyFeeTotal = 300;
    uint256 public sellFeeOp = 0;
    uint256 public sellFeeValidator = 800;
    uint256 public sellFeeTotal = 800;
    uint256 public bps = 10000;
    uint256 public _opTokensToSwap;
    uint256 public _validatorTokensToSwap;
    address public opFeeRecipient1 = 0xb8d7dA7E64271E274e132001F9865Ad8De5001C8;
    address public opFeeRecipient2 = 0x21CcABc78FC240892a54106bC7a8dC3880536347;
    address public opFeeRecipient3 = 0xd703f7b098262B0751c9A654eea332183D199A69;
    address public validatorFeeRecipient = 0x58917027C0648086f85Cd208E289095731cFDE1B;
    IUniswapV2Router public router;
    address public pair;
    bool public contractSellEnabled = true;
    uint256 public contractSellThreshold = _totalSupply / 5000;
    bool public mintingEnabled = true;
    bool public tradingEnabled = false;
    bool public isContractSelling = false;
    MicroValidator public microvalidator;
    address public microvalidatorAddress;
    bool public swapForETH = true;
    IERC20 public usdt = IERC20(USDT);
    uint256 public taxDistOp = 2700;
    uint256 public taxDistValidator = 7300;
    uint256 public taxDistBps = 10000;

    modifier contractSelling() {
        isContractSelling = true;
        _;
        isContractSelling = false;
    }

    constructor(address _priceFeed) AC(msg.sender) {
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(USDT, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WETH = router.WETH();
        microvalidator = new MicroValidator(
            "Annuity MicroValidators",
            "MicroValidator",
            address(this),
            msg.sender,
            _priceFeed,
            WETH
        );
        microvalidatorAddress = address(microvalidator);
        isDisabledExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isMaxExempt[msg.sender] = true;
        isDisabledExempt[microvalidatorAddress] = true;
        isFeeExempt[microvalidatorAddress] = true;
        isMaxExempt[microvalidatorAddress] = true;
        isDisabledExempt[address(0)] = true;
        isFeeExempt[address(0)] = true;
        isMaxExempt[address(0)] = true;
        isDisabledExempt[DEAD] = true;
        isFeeExempt[DEAD] = true;
        isMaxExempt[DEAD] = true;
        isMaxExempt[address(this)] = true;
        isUniswapPair[pair] = true;
        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        uint256 _toEmissions = 237000 * (10**_decimals);
        uint256 _toDeployer = _totalSupply - _toEmissions;
        _balances[msg.sender] = _toDeployer;
        emit Transfer(address(0), msg.sender, _toDeployer);
        _balances[microvalidatorAddress] = _toEmissions;
        emit Transfer(address(0), microvalidatorAddress, _toEmissions);
    }

    function mint(uint256 _amount) external onlyOwner {
        require(mintingEnabled, "Minting is disabled");
        _totalSupply += _amount;
        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] += _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        require(_balances[msg.sender] >= _amount);
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address _spender) external returns (bool) {
        return approve(_spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply)
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (bool) {
        if (isContractSelling) return _simpleTransfer(_sender, _recipient, _amount);
        require(tradingEnabled || isDisabledExempt[_sender], "Trading is currently disabled");
        address _routerAddress = address(router);
        bool _sell = isUniswapPair[_recipient] || _recipient == _routerAddress;
        if (!_sell && !isMaxExempt[_recipient])
            require((_balances[_recipient] + _amount) < maxWallet, "Max wallet has been triggered");
        if (_sell && _amount >= minAmountToTriggerSwap) {
            if (
                !isUniswapPair[msg.sender] &&
                !isContractSelling &&
                contractSellEnabled &&
                _balances[address(this)] >= contractSellThreshold
            ) _contractSell();
        }
        _balances[_sender] = _balances[_sender].sub(_amount, "Insufficient balance");
        uint256 _amountAfterFees = _amount;
        if (
            ((isUniswapPair[_sender] || _sender == _routerAddress) ||
                (isUniswapPair[_recipient] || _recipient == _routerAddress))
                ? !isFeeExempt[_sender] && !isFeeExempt[_recipient]
                : false
        ) _amountAfterFees = _collectFee(_sender, _recipient, _amount);
        _balances[_recipient] = _balances[_recipient].add(_amountAfterFees);
        emit Transfer(_sender, _recipient, _amountAfterFees);
        return true;
    }

    function _simpleTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (bool) {
        _balances[_sender] = _balances[_sender].sub(_amount, "Insufficient Balance");
        _balances[_recipient] = _balances[_recipient].add(_amount);
        return true;
    }

    function _collectFee(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (uint256) {
        bool _sell = isUniswapPair[_recipient] || _recipient == address(router);
        uint256 _feeDividend = _sell ? sellFeeTotal : buyFeeTotal;
        uint256 _feeDivisor = _amount.mul(_feeDividend).div(bps);
        if (_feeDividend > 0) {
            if (_sell) {
                if (sellFeeOp > 0) _opTokensToSwap += (_feeDivisor * sellFeeOp) / _feeDividend;
                if (sellFeeValidator > 0) _validatorTokensToSwap += (_feeDivisor * sellFeeValidator) / _feeDividend;
            } else {
                if (buyFeeOp > 0) _opTokensToSwap += (_feeDivisor * buyFeeOp) / _feeDividend;
                if (buyFeeValidator > 0) _validatorTokensToSwap += (_feeDivisor * buyFeeValidator) / _feeDividend;
            }
        }
        _balances[address(this)] = _balances[address(this)].add(_feeDivisor);
        emit Transfer(_sender, address(this), _feeDivisor);
        return _amount.sub(_feeDivisor);
    }

    function _contractSell() private contractSelling {
        uint256 _tokensTotal = _opTokensToSwap.add(_validatorTokensToSwap);
        if (swapForETH) {
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = USDT;
            path[2] = WETH;
            uint256 _ethBefore = address(this).balance;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                balanceOf(address(this)),
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 _ethAfter = address(this).balance.sub(_ethBefore);
            uint256 _ethOp = _ethAfter.mul(_opTokensToSwap).div(_tokensTotal);
            uint256 _ethValidator = _ethAfter.mul(_validatorTokensToSwap).div(_tokensTotal);
            _opTokensToSwap = 0;
            _validatorTokensToSwap = 0;
            if (_ethOp > 0) {
                payable(opFeeRecipient1).transfer((_ethOp * 3400) / 10000);
                payable(opFeeRecipient2).transfer((_ethOp * 3300) / 10000);
                payable(opFeeRecipient3).transfer((_ethOp * 3300) / 10000);
            }
            if (_ethValidator > 0) payable(validatorFeeRecipient).transfer(_ethValidator);
        } else {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = USDT;
            uint256 _usdtBefore = usdt.balanceOf(address(this));
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balanceOf(address(this)),
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 _usdtAfter = usdt.balanceOf(address(this)).sub(_usdtBefore);
            uint256 _usdtOp = _usdtAfter.mul(taxDistOp).div(taxDistBps);
            uint256 _usdtValidator = _usdtAfter.mul(taxDistValidator).div(taxDistBps);
            _opTokensToSwap = 0;
            _validatorTokensToSwap = 0;
            if (_usdtOp > 0) {
                usdt.transfer(opFeeRecipient1, (_usdtOp * 3400) / 10000);
                usdt.transfer(opFeeRecipient2, (_usdtOp * 3300) / 10000);
                usdt.transfer(opFeeRecipient3, (_usdtOp * 3300) / 10000);
            }
            if (_usdtValidator > 0) usdt.transfer(validatorFeeRecipient, _usdtValidator);
        }
    }

    function changeSwapForETH(bool _swapForETH) external onlyOwner {
        swapForETH = _swapForETH;
    }

    function changeTaxDist(
        uint256 _taxDistOp,
        uint256 _taxDistValidator,
        uint256 _taxDistBps
    ) external onlyOwner {
        taxDistOp = _taxDistOp;
        taxDistValidator = _taxDistValidator;
        taxDistBps = _taxDistBps;
    }

    function changeWETH(address _WETH) external onlyOwner {
        WETH = _WETH;
    }

    function changeUSDT(address _USDT) external onlyOwner {
        USDT = _USDT;
        usdt = IERC20(USDT);
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function setMinAmountToTriggerSwap(uint256 _minAmountToTriggerSwap) external onlyOwner {
        minAmountToTriggerSwap = _minAmountToTriggerSwap;
    }

    function toggleIsDisabledExempt(address _holder, bool _exempt) external onlyOwner {
        isDisabledExempt[_holder] = _exempt;
    }

    function getIsDisabledExempt(address _holder) external view returns (bool) {
        return isDisabledExempt[_holder];
    }

    function toggleIsFeeExempt(address _holder, bool _exempt) external onlyOwner {
        isFeeExempt[_holder] = _exempt;
    }

    function getIsFeeExempt(address _holder) external view returns (bool) {
        return isFeeExempt[_holder];
    }

    function toggleIsMaxExempt(address _holder, bool _exempt) external onlyOwner {
        isMaxExempt[_holder] = _exempt;
    }

    function getIsMaxExempt(address _holder) external view returns (bool) {
        return isMaxExempt[_holder];
    }

    function toggleIsUniswapPair(address _pair, bool _isPair) external onlyOwner {
        isUniswapPair[_pair] = _isPair;
    }

    function getIsUniswapPair(address _pair) external view returns (bool) {
        return isUniswapPair[_pair];
    }

    function configureContractSelling(bool _contractSellEnabled, uint256 _contractSellThreshold) external onlyOwner {
        contractSellEnabled = _contractSellEnabled;
        contractSellThreshold = _contractSellThreshold;
    }

    function setTransferTaxes(
        uint256 _buyFeeOp,
        uint256 _buyFeeValidator,
        uint256 _sellFeeOp,
        uint256 _sellFeeValidator,
        uint256 _bps
    ) external onlyOwner {
        buyFeeOp = _buyFeeOp;
        buyFeeValidator = _buyFeeValidator;
        buyFeeTotal = _buyFeeOp.add(_buyFeeValidator);
        sellFeeOp = _sellFeeOp;
        sellFeeValidator = _sellFeeValidator;
        sellFeeTotal = _sellFeeOp.add(_sellFeeValidator);
        bps = _bps;
    }

    function setTransferTaxRecipients(
        address _opFeeRecipient1,
        address _opFeeRecipient2,
        address _opFeeRecipient3,
        address _validatorFeeRecipient
    ) external onlyOwner {
        opFeeRecipient1 = _opFeeRecipient1;
        opFeeRecipient2 = _opFeeRecipient2;
        opFeeRecipient3 = _opFeeRecipient3;
        validatorFeeRecipient = _validatorFeeRecipient;
    }

    function updateRouting(
        address _router,
        address _pair,
        address _USDT
    ) external onlyOwner {
        router = IUniswapV2Router(_router);
        pair = _pair == address(0)
            ? IUniswapV2Factory(router.factory()).createPair(address(this), _USDT)
            : IUniswapV2Factory(router.factory()).getPair(address(this), _USDT);
        _allowances[address(this)][_router] = _totalSupply;
    }

    function permanentlyDisableMinting() external onlyOwner {
        mintingEnabled = false;
    }

    function toggleTrading(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
    }

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _token, address _recipient) external onlyOwner {
        IERC20(_token).transfer(_recipient, IERC20(_token).balanceOf(address(this)));
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    receive() external payable {}
}
