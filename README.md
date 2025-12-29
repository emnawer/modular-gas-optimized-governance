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
* **Legacy Consensus:** Includes a reference implementation of custom "2-of-3" multi-signature consensus without external dependencies.

## 📚 Documentation

Detailed documentation for each module can be found in the `docs/` folder:

* **[Access Control](docs/AccessControl.md):** Efficient role management using bitmasks.
* **[Security Modules](docs/Security.md):** User flags (Blacklist/VIP) and Asset Recovery.
* **[Governance](docs/Governance.md):** Custodian Multisig, Timelocks, and Hybrid patterns.
* **[Crowdsale](docs/Crowdsale.md):** Logic for ETH-to-Token sales.

## 📂 Quick Usage Examples

### 1. Access Control
```solidity
import "./modules/ContractAccessControl.sol";

contract MySecureContract is ContractAccessControl {
    uint256 constant ROLE_ADMIN = 1 << 0; // 1

    function adminAction() external onlyContractRole(ROLE_ADMIN) {
        // ...
    }
}
```

### 2. Hybrid Governance (The "Super Owner" Pattern)
A hybrid module bridging standard `Ownable` (fast, single-key) with `CustodianGovernance` (slow, multi-sig).

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