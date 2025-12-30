# Access Control Module

**File:** `modules/AccessControl.sol`

This module implements **Role-Based Access Control (RBAC)** using `uint256` bitmasks. This approach is significantly more gas-efficient than standard boolean mappings used by libraries like OpenZeppelin's `AccessControl`.

## ⚡ Why Bitmasks?

Standard implementations use `mapping(bytes32 => mapping(address => bool))`.
* **Storage:** Every new role granted to a user requires a new storage slot (20k gas).
* **Cost:** Granting 5 roles to a user costs ~100k gas in storage initiation.

**Our Approach:** `mapping(address => uint256)`
* **Storage:** We store up to **256 roles** in a single `uint256` storage slot.
* **Cost:** Granting 5 roles costs ~20k gas (1st role) + ~2k gas (subsequent roles).

## 🛠 Integration Guide

1. **Inherit** the contract.
2. **Define Roles** using bitshift operators (`<<`).
3. **Use Modifiers** to protect functions.

```solidity
import "../modules/AccessControl.sol";

contract MyContract is AccessControl {
    
    // Define Roles (Powers of 2)
    uint256 public constant ROLE_ADMIN  = 1 << 0; // 1
    uint256 public constant ROLE_MINTER = 1 << 1; // 2
    uint256 public constant ROLE_BURNER = 1 << 2; // 4

    constructor() {
        // Grant Admin role to deployer
        _grantRole(ROLE_ADMIN, msg.sender);
    }

    // Protect functions
    function mint(address to, uint256 amount) external onlyRole(ROLE_MINTER) {
        // ...
    }

    // Admin function to grant roles
    function addMinter(address newMinter) external onlyRole(ROLE_ADMIN) {
        _grantRole(ROLE_MINTER, newMinter);
    }
}
```

## 🔍 API Reference

### `hasRole(address account, uint256 role)`
Returns `true` if the account possesses the specified role bit.

### `_grantRole(uint256 role, address account)`
Internal. Adds the role bit to the account's mask. Does nothing if already granted.

### `_revokeRole(uint256 role, address account)`
Internal. Removes the role bit from the account's mask.