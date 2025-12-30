# Security Modules

**File:** `modules/Security.sol`

This file contains three abstract contracts designed to harden your smart contracts: `UserStatus`, `ReentrancyGuard`, and `Rescuable`.

---

## 1. UserStatus (User Flags)

Similar to our Access Control module, this manages user states (like Blacklists, VIP, KYC) using efficient bitmasks.

### Use Cases
* **Blacklisting:** Block malicious actors.
* **Freezing:** Halt all activity for a specific user.
* **KYC/VIP:** Grant special benefits to verified users.

### Integration

```solidity
import "../modules/Security.sol";

contract MyToken is UserStatus {
    
    // Define Flags
    uint256 public constant FLAG_BLACKLISTED = 1 << 0;
    uint256 public constant FLAG_VIP         = 1 << 1;

    // Use modifier to block restricted users
    function transfer(address to, uint256 amount) external checkUserStatus(msg.sender, FLAG_BLACKLISTED) {
        // Logic...
    }

    // Admin function to ban users
    function banUser(address user) external {
        _setUserFlag(user, FLAG_BLACKLISTED);
    }
}
```

---

## 2. ReentrancyGuard

A gas-optimized reentrancy protection mechanism to prevent common attack vectors where malicious contracts call back into vulnerable functions before the first execution completes.

### Features
* **Gas Optimized:** Uses counter-based approach with EIP-2200 gas refund
* **Clear Error Handling:** Reverts with `ReentrantCall()` error on detection
* **Minimal Overhead:** Only adds protection where needed

### Integration

```solidity
import "../modules/Security.sol";

contract MySecureContract is ReentrancyGuard {
    
    function sensitiveFunction() external nonReentrant {
        // Critical operations that could be vulnerable to reentrancy
        // External calls, state changes, etc.
    }
    
    function safeFunction() external {
        // This function doesn't need reentrancy protection
        // Simple read-only or low-risk operations
    }
}
```

### When to Use
Apply `nonReentrant` modifier to functions that:
* Perform external calls to untrusted contracts
* Handle token transfers or sensitive state changes
* Execute complex logic that could be interrupted

---

## 3. Rescuable (Asset Recovery)

A safety valve to recover assets accidentally sent to your contract address.

### Features
* **Recover ETH:** Withdraw native Ethereum.
* **Recover ERC20:** Withdraw any standard token.

### Integration
You **must** implement the `_checkRescueAuth()` function to define who is allowed to rescue funds.

```solidity
import "../modules/Security.sol";

contract MyVault is Rescuable {
    
    address public admin;

    // Implement the abstract auth check
    function _checkRescueAuth() internal view override {
        require(msg.sender == admin, "Unauthorized");
    }

    // Now you can call:
    // recoverETH(to, amount)
    // recoverERC20(token, to, amount)
}
```