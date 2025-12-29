# Granular Pausable Module

**File:** `modules/GranularPausable.sol`

This module allows you to pause specific parts of your contract (e.g., "Stop Minting" but "Allow Transfers") without shutting down the entire system. It uses `uint256` bitmasks for extreme gas efficiency.

## ⚡ Bitmask Logic

Instead of storing a boolean for every feature, we use bits in a single number:
* **0:** Not Paused
* **1:** Paused

**Example:**
* `FLAG_MINT` = `1` (Binary `001`)
* `FLAG_TRANSFER` = `2` (Binary `010`)

If `_pausedFlags` is `3` (Binary `011`), both are paused.

## 🛠 Integration

1. **Inherit** the contract.
2. **Define Flags** using powers of 2.
3. **Apply Modifier** `whenNotPaused` to your functions.

```solidity
import "../modules/GranularPausable.sol";

contract MyToken is GranularPausable {
    
    // Define Flags
    uint256 public constant PAUSE_MINT     = 1 << 0; // 1
    uint256 public constant PAUSE_TRANSFER = 1 << 1; // 2

    // Apply modifier
    function mint(address to, uint256 amount) external whenNotPaused(PAUSE_MINT) {
        // ...
    }

    function transfer(address to, uint256 amount) public override whenNotPaused(PAUSE_TRANSFER) {
        // ...
    }

    // Admin function to toggle
    function setPause(uint256 flag, bool paused) external onlyAdmin {
        if (paused) _pauseFeature(flag);
        else _unpauseFeature(flag);
    }
}
```

## 🔍 API Reference

### `whenNotPaused(uint256 flag)`
Modifier. Reverts if the specified flag bit is set to 1.

### `isFeaturePaused(uint256 flag)`
Returns `true` if the flag is paused.

### `_pauseFeature(uint256 flag)`
Internal. Sets the bit to 1 (Paused).

### `_unpauseFeature(uint256 flag)`
Internal. Sets the bit to 0 (Unpaused).