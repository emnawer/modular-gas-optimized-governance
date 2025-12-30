# **Modular Gas-Optimized Governance Suite**

A lightweight, gas-optimized Solidity library for modular governance and access control. This suite utilizes uint256 bitmasks for permission management, offering significant gas savings over traditional boolean mappings.  
This repository contains standalone abstract contracts designed to be dropped into any DeFi project requiring efficient state management.

## 📜 LGPL License Benefits

This project is licensed under the GNU Lesser General Public License (LGPL). Key benefits of LGPL over GPL for this project:

- **Linking Flexibility**: Projects can link to this library without being subject to LGPL's copyleft requirements, as long as they only use the library through its public interface.
- **Commercial Friendliness**: Businesses can integrate this library into their proprietary projects without being required to open-source their entire codebase.
- **Better Adoption**: The permissive nature of LGPL encourages wider adoption in the ecosystem while still ensuring improvements to the library itself remain open source.
- **Interoperability**: Works well with other open source licenses, making it easier to integrate with various projects in the blockchain space.

For more details, see the full [LICENSE](LICENSE) file.
## **🚀 Quick Start & Deployment**

### **Prerequisites**
- [Node.js](https://nodejs.org/) (v16+ recommended)
- [Truffle Suite](https://trufflesuite.com/) (for development and deployment)
- [Git](https://git-scm.com/)

### **Installation**
```bash
git clone https://github.com/emnawer/modular-gas-optimized-governance.git
cd modular-gas-optimized-governance
npm install
npm install -g ganache
```

### **Deployment Options**

#### **1. Local Development**
```bash
# Start local development blockchain
truffle develop

# In the Truffle console, compile and migrate:
compile
migrate

# Or for a specific network configuration:
truffle migrate --network development
```

#### **2. One-Click Deploy**
Deploy directly using your preferred online IDE:

[![Open in Replit](https://replit.com/badge/github/emnawer/modular-gas-optimized-governance)](https://replit.com/new/github/emnawer/modular-gas-optimized-governance/tree/dev)
[![Open in CodeSandbox](https://img.shields.io/badge/Open%20in-CodeSandbox-blue?style=flat&logo=codesandbox)](https://codesandbox.io/s/github/emnawer/modular-gas-optimized-governance/tree/dev)


### **Testnet/Mainnet Deployment**
1. Configure your `truffle-config.js` with the desired network settings
2. Set up your `.env` file with your private key and RPC URL
3. Run the migration:
   ```bash
   truffle migrate --network <network-name>
   ```

### **Verification**
After deployment, verify your contract on Etherscan using the Truffle verification plugin:

1. Install the verification plugin:
   ```bash
   npm install -D truffle-plugin-verify
   ```

2. Add this to your `truffle-config.js`:
   ```javascript
   plugins: ['truffle-plugin-verify']
   ```

3. Verify your contract:
   ```bash
   truffle run verify ContractName --network <network-name>
   ```

## **⚡ Key Features**

* **Gas Optimized:** Uses uint256 bitmasks for Role-Based Access Control (RBAC) and User Statuses (e.g., Blacklist, VIP), reducing storage usage and gas costs compared to standard libraries.  
* **Modular Design:** Abstract contracts that can be mixed and matched to build complex, secure systems.  
* **Multi-signature Governance:** Custom "2-of-3" multi-signature consensus without external dependencies.  
* **Reentrancy Protection:** Built-in reentrancy guard for critical functions to prevent common attack vectors.  
* **Comprehensive Security:** User status management, asset recovery, and granular pause controls.

## 📚 Documentation

Detailed documentation for each module can be found in the `docs/` folder:

* **[Access Control](docs/AccessControl.md):** Efficient role management using bitmasks.
* **[Security Modules](docs/Security.md):** User flags (Blacklist/VIP), reentrancy protection, and Asset Recovery.
* **[Governance](docs/Governance.md):** Custodian Multisig, Timelocks, and Hybrid patterns.
* **[Crowdsale](docs/Crowdsale.md):** Logic for ETH-to-Token sales.
* **[Pausable](docs/Pausable.md):** Granular feature-level pause controls.

## 📂 Quick Usage Examples

### 1. Access Control
```solidity
import "./modules/AccessControl.sol";

contract MySecureContract is AccessControl {
    uint256 constant ROLE_ADMIN = 1 << 0; // 1

    function adminAction() external onlyRole(ROLE_ADMIN) {
        // ...
    }
}
```

### 2. Granular Pausable
```solidity
import "./modules/GranularPausable.sol";

contract MyToken is GranularPausable {
    uint256 public constant PAUSE_MINT = 1 << 0; // 1
    uint256 public constant PAUSE_TRANSFER = 1 << 1; // 2

    function mint(address to, uint256 amount) external whenNotPaused(PAUSE_MINT) {
        // Minting can be paused independently
    }

    function transfer(address to, uint256 amount) public override whenNotPaused(PAUSE_TRANSFER) {
        // Transfers can be paused independently
    }

    function pauseMinting() external onlyAdmin {
        _pauseFeature(PAUSE_MINT);
    }
}
```

### 3. Reentrancy Protection
```solidity
import "./modules/Security.sol";

contract MySecureContract is ReentrancyGuard {
    
    function sensitiveOperation() external nonReentrant {
        // This function is protected against reentrancy attacks
        // Critical state changes and external calls go here
    }
}
```

### 4. Crowdsale
```solidity
import "./modules/Crowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyTokenSale is Crowdsale, ERC20 {
    constructor() ERC20("MyToken", "MTK") {
        tokensPerETH = 1000; // 1 ETH = 1000 tokens
        saleActive = true;
    }

    // Define how tokens are delivered to buyers
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
        _mint(beneficiary, tokenAmount); // Mint new tokens
    }

    // Define who can manage the sale
    function _checkSaleAuth() internal view override {
        require(msg.sender == owner(), "Not authorized");
    }
}
```

### 5. Timelock
```solidity
import "./modules/Timelock.sol";

contract CriticalSettings is Timelock {
    uint256 public criticalParameter;
    
    function scheduleParameterChange(uint256 newValue) external {
        bytes32 opId = keccak256(abi.encode("PARAM_CHANGE", newValue));
        _scheduleOperation(opId, 3 days); // 3 day delay
    }
    
    function executeParameterChange(uint256 newValue) external {
        bytes32 opId = keccak256(abi.encode("PARAM_CHANGE", newValue));
        _checkAndClearOperation(opId); // Will revert if delay not passed
        criticalParameter = newValue;
    }
}
```

### 6. Hybrid Governance (The "Super Owner" Pattern)

A powerful pattern combining standard `Ownable` speed with `CustodianGovernance` security, perfect for projects that need both operational efficiency and decentralized oversight.

#### 🎯 When to Use Hybrid Governance

* **DeFi Protocols:** Fast parameter updates with community oversight on critical changes
* **Gaming Platforms:** Instant game settings with token supply controls
* **Enterprise DeFi:** Business agility with board-level security controls
* **DAO Transition:** Start with centralized control, gradually decentralize

#### 🛠 Implementation Example

```solidity
import "./modules/CustodianGovernance.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HybridApp is Ownable, CustodianGovernance {
    // 1. Fast Action (Owner only)
    function updateSetting() external onlyOwner { ... }

    // 2. Powerful Action (Custodians only)
    function _executeProposal(uint256 id) internal override {
        // Vote to replace owner, etc.
    }
}
```

#### 📊 Speed vs Security Trade-offs

| Operation Type | Speed | Control | Best For |
|----------------|-------|---------|----------|
| **Daily Operations** | ⚡ Instant | Owner | Fees, parameters, metadata |
| **Emergency Actions** | ⚡ Instant | Owner | Pause, emergency fixes |
| **Critical Changes** | 🐢 Voting | Custodians | Minting, upgrades, ownership |
| **Community Decisions** | 🐢 Voting | Custodians | Major policy changes |

#### 🚀 Key Benefits

* **No Daily Bottlenecks:** Routine operations don't require voting
* **Community Oversight:** Critical decisions need multi-signature approval  
* **Accountability:** Custodians can remove abusive owners
* **Flexibility:** Can evolve toward full DAO governance over time
* **Emergency Response:** Owner can act fast in crises

#### ⚠️ Security Best Practices

1. **Strong Owner Security:** Use multi-sig wallets or hardware wallets for owner key
2. **Diverse Custodians:** Select from different organizations/geographies
3. **Clear Proposal Types:** Define what requires voting vs instant execution
4. **Gradual Decentralization:** Start centralized, increase community control over time

For a complete working example, see [OpenZeppelinToken.sol](contracts/OpenZeppelinToken.sol).


## **⛽ Why Bitmasks?**

Standard AccessControl implementations often use a mapping(bytes32 => mapping(address => bool)). This means every new role a user gains requires a new 20k gas storage write (SSTORE).  
By using mapping(address => uint256), we can store **256 different roles** for a user in a **single storage slot**.

1. **Granting 1st Role:** ~20k Gas (SSTORE Init).  
2. **Granting 2nd Role:** ~2.1k Gas (SSTORE Warm).  
3. **Checking Roles:** Extremely cheap bitwise operations.

## **⚠️ Disclaimer**

This code is provided as open-source software with no waranty of any kind. While it implements robust logic and standard patterns, these specific modules have **not** undergone a formal external audit. For production systems handling significant value, I recommend hiring an auditor.

## **📄 License**

LGPL-2.1-or-later © 2025 Emnawer