// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title ERC20Combo
 * @notice A gas-optimized ERC20 implementation with built-in EIP-2612 Permit support.
 * @dev Replaces OpenZeppelin ERC20 + ERC20Permit dependencies.
 */
abstract contract ERC20Combo {
    
    // ===========================================
    //             State Variables
    // ===========================================
    
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    // EIP-712 Constants
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // ===========================================
    //                Events
    // ===========================================
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ===========================================
    //                Errors
    // ===========================================
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
    error ERC20PermitExpired();
    error ERC20InvalidSigner();

    // ===========================================
    //             Constructor
    // ===========================================
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        
        // Initialize EIP-712 Domain Separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // ===========================================
    //           ERC20 Functions
    // ===========================================

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // ===========================================
    //           EIP-2612 Permit
    // ===========================================

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert ERC20PermitExpired();

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0) || signer != owner) revert ERC20InvalidSigner();

        _approve(owner, spender, value);
    }

    // ===========================================
    //           Internal Logic
    // ===========================================

    function _transfer(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) revert ERC20InvalidSender(address(0));
        if (to == address(0)) revert ERC20InvalidReceiver(address(0));

        _update(from, to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. 
     * Handles the actual balance updates.
     */
    function _update(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            // Mint
            totalSupply += amount;
        } else {
            uint256 fromBalance = balanceOf[from];
            if (fromBalance < amount) revert ERC20InsufficientBalance(from, fromBalance, amount);
            unchecked {
                balanceOf[from] = fromBalance - amount;
            }
        }

        if (to == address(0)) {
            // Burn
            unchecked {
                totalSupply -= amount;
            }
        } else {
            unchecked {
                balanceOf[to] += amount;
            }
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20InvalidReceiver(address(0));
        _update(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20InvalidSender(address(0));
        _update(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (owner == address(0)) revert ERC20InvalidApprover(address(0));
        if (spender == address(0)) revert ERC20InvalidSpender(address(0));

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}