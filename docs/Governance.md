# Governance Modules

**Files:** `modules/CustodianGovernance.sol`, `modules/Timelock.sol`

This suite provides modular governance components ranging from simple delays to complex multi-signature voting.

---

## 1. Custodian Governance (Multisig)

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
import "../modules/Timelock.sol";

contract CriticalSettings is Timelock {
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

A powerful pattern combining standard `Ownable` speed with `Custodian` security, creating the best of both worlds for decentralized applications.

### 🎯 Why Use Hybrid Governance?

* **Daily Efficiency:** Handle routine operations instantly without voting delays
* **Collective Oversight:** Critical decisions require multi-signature approval
* **Accountability:** The community can remove abusive owners through voting
* **Emergency Response:** Owner has emergency powers, but custodians provide checks and balances

### 👥 Roles & Responsibilities

* **CEO (Owner):** Handles daily tasks instantly, emergency response, and routine operations
* **Board (Custodians):** Provides oversight, can override decisions, and can vote to replace the owner

### 🛠 Implementation Pattern

```solidity
import "../modules/CustodianGovernance.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HybridApp is Ownable, CustodianGovernance {
    
    // ========== Fast Actions (Owner Only) ==========
    // These execute instantly without voting
    
    function updateMetadata(string memory name, string memory symbol) external onlyOwner {
        // Routine updates that don't affect security
    }
    
    function emergencyPause() external onlyOwner {
        // Crisis response - immediate action needed
    }
    
    function setDailyParameters(uint256 param) external onlyOwner {
        // Operational settings that change frequently
    }
    
    // ========== Slow Actions (Custodians Only) ==========
    // These require multi-signature voting for security
    
    function proposeMint(address to, uint256 amount) external onlyRole(ROLE_CUSTODIAN) {
        _createProposal("Mint tokens", PROPOSAL_MINT, abi.encode(to, amount), 0);
    }
    
    function proposeReplaceOwner(address newOwner) external onlyRole(ROLE_CUSTODIAN) {
        _createProposal("Replace contract owner", PROPOSAL_REPLACE_OWNER, abi.encode(newOwner), 0);
    }
    
    // ========== Internal Implementation ==========
    
    function _executeProposal(uint256 proposalId) internal override {
        (uint256 proposalType, bytes memory data, ) = getProposal(proposalId);
        
        if (proposalType == PROPOSAL_MINT) {
            (address to, uint256 amount) = abi.decode(data, (address, uint256));
            _mint(to, amount);
        } else if (proposalType == PROPOSAL_REPLACE_OWNER) {
            address newOwner = abi.decode(data, (address));
            _transferOwnership(newOwner); // Critical: Board can fire CEO!
        }
    }
}
```

### 📋 Decision Matrix

| Operation | Speed | Who Controls | Risk Level | Example |
|-----------|-------|--------------|------------|---------|
| **Metadata Updates** | ⚡ Instant | Owner | Low | Change token name |
| **Emergency Pause** | ⚡ Instant | Owner | Medium | Stop exploits |
| **Parameter Tweaks** | ⚡ Instant | Owner | Low | Adjust fees |
| **Token Minting** | 🐢 Slow | Custodians | High | Create new tokens |
| **Owner Replacement** | 🐢 Slow | Custodians | Critical | Remove abusive owner |
| **Protocol Changes** | 🐢 Slow | Custodians | High | Upgrade logic |

### 🚀 Best Practices

1. **Clear Separation:** Define which operations are fast vs slow before deployment
2. **Custodian Diversity:** Choose custodians from different organizations/communities
3. **Emergency Plans:** Document when owner emergency powers should be used
4. **Gradual Handover:** Consider transferring ownership to a DAO as the project matures

### ⚠️ Security Considerations

* **Owner Key Security:** The owner private key must be heavily protected
* **Custodian Selection:** Choose trustworthy, active community members
* **Proposal Clarity:** All proposals should have clear descriptions and parameters
* **Voting Participation:** Ensure sufficient custodian participation for important decisions

See [OpenZeppelinToken.sol](../contracts/OpenZeppelinToken.sol) for a complete working example.