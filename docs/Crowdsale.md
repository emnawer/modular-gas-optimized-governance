# Crowdsale Module

**File:** `modules/Crowdsale.sol`

An abstract base contract for direct ETH-to-Token sales. It handles the math and state, while allowing you to define *how* the tokens are delivered (minted vs transferred).

## Features
* **Configurable Rate:** Set how many tokens 1 ETH buys.
* **Toggle:** Pause/Unpause sales easily.
* **Safety:** Abstract delivery method prevents logic errors.

## Integration

```solidity
import "../modules/Crowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyICO is Crowdsale, ERC20 {
    
    constructor() ERC20("ICO Token", "ICO") {
        tokensPerETH = 1000; // 1 ETH = 1000 Tokens
        saleActive = true;
    }

    // Define how tokens are sent
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
        // Option A: Mint new tokens
        _mint(beneficiary, tokenAmount);
        
        // Option B: Transfer from reserve
        // _transfer(address(this), beneficiary, tokenAmount);
    }

    // Define who can update settings
    function _checkSaleAuth() internal view override {
        require(msg.sender == admin, "Not Admin");
    }
}
```

## 🔍 API Reference

### State Variables
* `tokensPerETH` - How many tokens one ETH buys (set in constructor or by admin)
* `saleActive` - Boolean flag to enable/disable the sale

### Core Functions

#### `buyTokens(address beneficiary)`
External payable function. Users call this to send ETH and receive tokens.
* **ETH Amount:** `msg.value`
* **Token Amount:** Calculated as `msg.value * tokensPerETH`
* **Requirements:** Sale must be active and beneficiary must not be zero address

#### `_deliverTokens(address beneficiary, uint256 tokenAmount)`
Internal function you **must** implement. Defines how tokens are delivered.
* **Common Patterns:**
  * Mint new tokens: `_mint(beneficiary, tokenAmount)`
  * Transfer from reserve: `_transfer(address(this), beneficiary, tokenAmount)`

#### `_checkSaleAuth()`
Internal view function you **must** implement. Defines who can manage sale settings.
* **Common Patterns:**
  * Owner only: `require(msg.sender == owner())`
  * Role-based: `require(hasRole(msg.sender, ROLE_ADMIN))`

#### `toggleSale()`
External function to pause/resume the sale (requires auth via `_checkSaleAuth()`).

#### `setRate(uint256 newRate)`
External function to update tokens-per-ETH rate (requires auth via `_checkSaleAuth()`).

## 🚀 Use Cases

* **ICO/IDO:** Initial token offering for project funding
* **Token Launch:** Fair launch with fixed pricing
* **Fundraising:** Community round or public sale
* **Liquidity Mining:** Sell tokens for ETH to provide initial liquidity

## ⚠️ Security Considerations

### 🛡️ Critical Security Points

1. **Rate Validation:** Ensure `tokensPerETH` is reasonable to prevent pricing errors
2. **Sale Duration:** Consider implementing automatic sale end conditions
3. **Cap Management:** Add maximum ETH or token caps if needed
4. **Front-running Protection:** Consider commit-reveal schemes for large sales

### 🔒 Recommended Enhancements

```solidity
// Add to your contract for additional security

uint256 public constant MAX_ETH_CAP = 1000 ether; // Maximum ETH to raise
uint256 public totalETHRaised;

modifier withinCap() {
    require(totalETHRaised + msg.value <= MAX_ETH_CAP, "Cap exceeded");
    _;
}

function buyTokens(address beneficiary) external payable withinCap {
    totalETHRaised += msg.value;
    // ... rest of logic
}
```

### 📊 Best Practices

* **Start with Low Rates:** Test with small amounts before opening to public
* **Gradual Increases:** Consider tiered pricing for early supporters
* **Transparent Communication:** Clearly announce sale parameters in advance
* **Emergency Controls:** Implement pause functionality for unexpected issues

### ⚡ Gas Optimization Tips

* **Batch Processing:** Consider allowing multiple purchases in one transaction
* **Efficient Math:** Use fixed-point arithmetic for precise rate calculations
* **Storage Optimization:** Minimize state changes in purchase functions