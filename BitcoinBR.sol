// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

/*
  Bitcoin BR (BTCBR) - Final Version (Verification Ready)

  - Name: Bitcoin BR
  - Symbol: BTCBR
  - Decimals: 25
  - Initial Supply: 21,000,000,000 * 10^25  (minted to INITIAL_OWNER)
  - MAX_SUPPLY (cap): 30,000,000,000 * 10^25
  - INITIAL_OWNER: 0x841f4125966b30cD7817D2745BEAE4D5E4A24928
  - Includes: mint(), burn(), burnFrom(), transferability
  - Fully verification-ready for BscScan (single-file source)
*/

/* -----------------------------------------
   Context and Interfaces
   ----------------------------------------- */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/* -----------------------------------------
   Basic ERC20 implementation
   ----------------------------------------- */
contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint8) { return 18; }

    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked { _approve(sender, _msgSender(), currentAllowance - amount); }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to zero");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from zero");
        uint256 bal = _balances[account];
        require(bal >= amount, "ERC20: burn exceeds balance");
        unchecked {
            _balances[account] = bal - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

/* -----------------------------------------
   Ownable (constructor-based owner)
   ----------------------------------------- */
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Ownable: zero owner");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view virtual returns (address) { return _owner; }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller not owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: zero newOwner");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

/* -----------------------------------------
   BitcoinBR main contract
   ----------------------------------------- */
contract BitcoinBR is ERC20, Ownable {

    uint8 private constant _DECIMALS = 25;

    address private constant INITIAL_OWNER = 0x841f4125966b30cD7817D2745BEAE4D5E4A24928;

    uint256 private constant INITIAL_SUPPLY = 21_000_000_000 * (10 ** 25);
    uint256 public constant MAX_SUPPLY = 30_000_000_000 * (10 ** 25);

    constructor() ERC20("Bitcoin BR", "BTCBR") Ownable(INITIAL_OWNER) {
        _mint(INITIAL_OWNER, INITIAL_SUPPLY);
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        require(totalSupply() + amount <= MAX_SUPPLY, "BitcoinBR: cap exceeded");
        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn exceeds allowance");
        unchecked { _approve(account, _msgSender(), currentAllowance - amount); }
        _burn(account, amount);
    }
}
Final verified version (v0.8.26, decimals=25, max supply added
