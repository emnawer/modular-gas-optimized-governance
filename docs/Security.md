# Security Modules

**File:** `modules/SecurityModules.sol`

This file contains two abstract contracts designed to harden your smart contracts: `BitmaskUserStatus` and `Rescuable`.

---

## 1. BitmaskUserStatus (User Flags)

Similar to our Access Control module, this manages user states (like Blacklists, VIP, KYC) using efficient bitmasks.

### Use Cases
* **Blacklisting:** Block malicious actors.
* **Freezing:** Halt all activity for a specific user.
* **KYC/VIP:** Grant special benefits to verified users.

### Integration

```solidity
import "../modules/SecurityModules.sol";

contract MyToken is BitmaskUserStatus {
    
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

## 2. Rescuable (Asset Recovery)

A safety valve to recover assets accidentally sent to your contract address.

### Features
* **Recover ETH:** Withdraw native Ethereum.
* **Recover ERC20:** Withdraw any standard token.

### Integration
You **must** implement the `_checkRescueAuth()` function to define who is allowed to rescue funds.

```solidity
import "../modules/SecurityModules.sol";

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