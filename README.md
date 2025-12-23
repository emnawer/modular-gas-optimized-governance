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

[![Open in Replit](https://replit.com/badge/github/emnawer/modular-gas-optimized-governance)](https://replit.com/new/github/emnawer/modular-gas-optimized-governance)
[![Open in CodeSandbox](https://img.shields.io/badge/Open%20in-CodeSandbox-blue?style=flat&logo=codesandbox)](https://codesandbox.io/s/github/emnawer/modular-gas-optimized-governance)


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

## **📂 Modules & Usage Examples**

### **1. Access Control (ContractAccessControl.sol)**

A generic RBAC module using bitwise flags. Stores up to 256 distinct roles in a single storage slot per user.  
**Usage Example:**
```solidity
import "./modules/ContractAccessControl.sol";

contract MySecureContract is ContractAccessControl {  
    // Define Roles as powers of 2  
    uint256 constant ROLE_ADMIN  = 1 << 0; // 1  
    uint256 constant ROLE_MINTER = 1 << 1; // 2

    constructor() {  
        _grantContractRole(ROLE_ADMIN, msg.sender);  
    }

    function mint(address to, uint256 amount) external onlyContractRole(ROLE_MINTER) {  
        // Minting logic...  
    }

    function addMinter(address newMinter) external onlyContractRole(ROLE_ADMIN) {  
        _grantContractRole(ROLE_MINTER, newMinter);  
    }  
}
```
### **2. Security (SecurityModules.sol)**

Includes BitmaskUserStatus for user states and Rescuable for asset recovery.  
**Usage Example:**
```solidity
import "./modules/SecurityModules.sol";  
import "./modules/ContractAccessControl.sol";

contract MyToken is ContractAccessControl, BitmaskUserStatus, Rescuable {  
    uint256 constant ROLE_ADMIN   = 1 << 0;  
    uint256 constant FLAG_BANNED  = 1 << 0; // 1  
    uint256 constant FLAG_VIP     = 1 << 1; // 2

    // Implement abstract function from Rescuable  
    function _checkRescueAuth() internal view override {  
        require(hasContractRole(msg.sender, ROLE_ADMIN), "Not Admin");  
    }

    function banUser(address user) external onlyContractRole(ROLE_ADMIN) {  
        _setUserFlag(user, FLAG_BANNED);  
    }

    function transfer(address to, uint256 amount) external checkUserStatus(msg.sender, FLAG_BANNED) {  
        // Transfer fails if sender has FLAG_BANNED  
        // ... logic  
    }  
}
```
### **3. Time Management (TimelockModule.sol)**

A lightweight delay mechanism. Operations must be scheduled, wait for the delay, and then executed.  
**Usage Example:**
```solidity
import "./modules/TimelockModule.sol";

contract TaxManager is TimelockModule {  
    uint256 public taxRate = 5;  
    uint256 public constant DELAY = 1 days;

    // 1. Schedule the change  
    function scheduleTaxUpdate(uint256 newRate) external {  
        bytes32 opId = keccak256(abi.encode("SET_TAX", newRate));  
        _scheduleOperation(opId, DELAY);  
    }

    // 2. Execute after 1 day  
    function executeTaxUpdate(uint256 newRate) external {  
        bytes32 opId = keccak256(abi.encode("SET_TAX", newRate));  
          
        // This will revert if 1 day hasn't passed  
        _checkAndClearOperation(opId);

        taxRate = newRate;  
    }  
}
```
### **4. Sales (CrowdsaleModule.sol)**

Base logic for selling tokens for ETH.  
**Usage Example:**
```solidity
import "./modules/CrowdsaleModule.sol";  
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenSale is CrowdsaleModule, ERC20 {  
    constructor() ERC20("SaleToken", "SALE") {  
        // 1 ETH = 1000 Tokens  
        tokensPerETH = 1000;  
        saleActive = true;  
    }

    // Implement the token delivery logic  
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {  
        _mint(beneficiary, tokenAmount);  
    }

    // Implement auth for admin functions  
    function _checkSaleAuth() internal view override {  
        require(msg.sender == address(0x123...), "Not Admin");  
    }  
}
```
### **5. Custom Governance (CustodianGovernance.sol)**

A legacy module requiring 2/3 consensus for actions.  
**Usage Example:**  
```solidity
import "./modules/CustodianGovernance.sol";

contract TreasuryChest is CustodianGovernance {  
      
    constructor(address[] memory _initialCustodians) CustodianGovernance(_initialCustodians) {}

    // Function to propose paying someone  
    // description: "PAY:0x123...:500"  
      
    function _executeProposal(uint256 proposalId) internal override {  
        Proposal storage p = proposals[proposalId];  
          
        // Parse description to find action (Pseudo-code)  
        // If "PAY", transfer funds...  
        // This logic is manual in this legacy module  
    }  
}
```
### **6. Hybrid Governance (The "Super Owner" Pattern)**

A hybrid module bridging standard Ownable (fast, single-key) with CustodianGovernance (slow, multi-sig). This pattern is excellent for systems that need daily operational speed but ultimate security.  
**Concept:**

* **Owner (CEO):** Can perform daily low-risk tasks instantly.  
* **Custodians (Board):** Can vote to replace the Owner or perform high-risk actions.

**Usage Example with Bitmask Proposal Types:**  
```solidity
import "./modules/CustodianGovernance.sol";  
import "@openzeppelin/contracts/access/Ownable.sol";

contract HybridApp is Ownable, CustodianGovernance {  
      
    // Define Proposal Types (Bitmasks)  
    // 1 = Admin Action (e.g. Replace Owner)  
    // 2 = Financial Action (e.g. Withdraw)  
    uint256 constant TYPE_ADMIN     = 1 << 0;   
    uint256 constant TYPE_FINANCIAL = 1 << 1;

    constructor(address[] memory _custodians)   
        Ownable(msg.sender)   
        CustodianGovernance(_custodians)   
    {}

    // 1. Fast Action (Owner only)  
    function updateUncriticalSetting(uint256 val) external onlyOwner {  
        // ... logic  
    }

    // 2. Slow/Powerful Action (Custodians only)  
    // Overriding internal execution logic  
    function _executeProposal(uint256 proposalId) internal override {  
        // Fetch proposal details...  
        // If Type == TYPE_ADMIN: _transferOwnership(newOwner);  
        // If Type == TYPE_FINANCIAL: withdrawFunds();  
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