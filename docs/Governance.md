# Governance Modules

**Files:** `modules/CustodianGovernance.sol`, `modules/TimelockModule.sol`

This suite provides modular governance components ranging from simple delays to complex multi-signature voting.

---

## 1. Custodian Governance (Legacy Multisig)

A gas-optimized, on-chain multi-signature system. It requires a 2/3 supermajority of custodians to execute proposals.

### Key Features
* **Bitmask Proposal Types:** Proposals can be tagged (e.g., `TYPE_FINANCIAL`, `TYPE_ADMIN`).
* **Granular Voting:** Custodians can be restricted to voting only on specific proposal types.
* **Quorum:** Hardcoded to > 66% (2/3).

### Integration

```solidity
import "../modules/CustodianGovernance.sol";

contract Treasury is CustodianGovernance {
    
    uint256 constant TYPE_TRANSFER = 1 << 0;

    constructor(address[] memory _custodians) CustodianGovernance(_custodians) {}

    // 1. Define Execution Logic
    function _executeProposal(uint256 proposalId) internal override {
        Proposal storage p = proposals[proposalId];
        
        if (p.typeMask == TYPE_TRANSFER) {
            // Logic to parse p.description and transfer funds...
        }
    }
}
```

---

## 2. Timelock Module

A lightweight delay mechanism. Useful for preventing "Rug Pulls" or giving users time to exit before a critical change occurs.

### Lifecycle
1.  **Schedule:** `_scheduleOperation(opId, delay)`
2.  **Wait:** `block.timestamp` must increase by `delay`.
3.  **Execute:** `_checkAndClearOperation(opId)`

### Integration

```solidity
import "../modules/TimelockModule.sol";

contract CriticalSettings is TimelockModule {
    uint256 public param;
    
    function updateParam(uint256 newVal) external {
        // Unique ID for this operation
        bytes32 opId = keccak256(abi.encode("UPDATE", newVal));
        
        // This will revert if not scheduled/ready
        _checkAndClearOperation(opId);
        
        param = newVal;
    }
}
```

---

## 3. Hybrid Governance (The "Super Owner")

A powerful pattern combining standard `Ownable` speed with `Custodian` security.

* **CEO (Owner):** Handles daily tasks instantly.
* **Board (Custodians):** Can vote to fire the CEO or override decisions.

See `modules/HybridGovernance.sol` (if implemented) or use the pattern described in the main README.