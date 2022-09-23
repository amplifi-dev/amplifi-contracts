/**
 *Submitted for verification at Etherscan.io on 2022-06-10
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AC {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, AC {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    string private _base = "https://cdn.theannuity.io/";

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name_,
        string memory symbol_,
        address _owner
    ) AC(_owner) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _base;
    }

    function changeBaseURI(string memory _baseNew) external onlyOwner {
        _base = _baseNew;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface INetwork {
    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;
}

contract Network1 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) public totalRewardsDistributed;
    mapping(address => mapping(address => uint256)) public totalRewardsToUser;
    mapping(address => bool) public allowed;
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

    constructor(
        address _router,
        address _owner,
        address _weth
    ) AC(_owner) {
        router = _router != address(0)
            ? IUniswapV2Router(_router)
            : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(
                    amount
                );
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

contract Network2 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) public totalRewardsDistributed;
    mapping(address => mapping(address => uint256)) public totalRewardsToUser;
    mapping(address => bool) public allowed;
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

    constructor(
        address _router,
        address _owner,
        address _weth
    ) AC(_owner) {
        router = _router != address(0)
            ? IUniswapV2Router(_router)
            : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(
                    amount
                );
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

contract Network3 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) public totalRewardsDistributed;
    mapping(address => mapping(address => uint256)) public totalRewardsToUser;
    mapping(address => bool) public allowed;
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

    constructor(
        address _router,
        address _owner,
        address _weth
    ) AC(_owner) {
        router = _router != address(0)
            ? IUniswapV2Router(_router)
            : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(
                    amount
                );
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

contract Network4 is INetwork, AC {
    using SafeMath for uint256;
    uint256 internal constant max = 2**256 - 1;
    address _token;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 BASE;
    IUniswapV2Router router;
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) public totalRewardsDistributed;
    mapping(address => mapping(address => uint256)) public totalRewardsToUser;
    mapping(address => bool) public allowed;
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

    constructor(
        address _router,
        address _owner,
        address _weth
    ) AC(_owner) {
        router = _router != address(0)
            ? IUniswapV2Router(_router)
            : IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        allowed[_weth] = true;
        BASE = IERC20(_weth);
        BASE.approve(_router, max);
    }

    receive() external payable {}

    function getClaimedDividendsTotal(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getClaimedDividends(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function changeRouterVersion(address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        router = _uniswapV2Router;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount > 0 && shares[shareholder].amount == 0) addShareholder(shareholder);
        else if (amount == 0 && shares[shareholder].amount > 0) removeShareholder(shareholder);
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder, address rewardAddress) internal {
        require(allowed[rewardAddress], "Invalid reward address!");
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getPendingDividend(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if (rewardAddress == address(BASE)) {
                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(
                    amount
                );
            }
        }
    }

    function claimDividend(address claimer, address rewardAddress) external onlyToken {
        distributeDividend(claimer, rewardAddress);
    }

    function getPendingDividend(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

    function drainGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function drainToken(address _address, address _to) external onlyOwner {
        IERC20(_address).transfer(_to, IERC20(_address).balanceOf(address(this)));
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
