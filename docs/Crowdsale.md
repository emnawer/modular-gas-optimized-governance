# Crowdsale Module

**File:** `modules/CrowdsaleModule.sol`

An abstract base contract for direct ETH-to-Token sales. It handles the math and state, while allowing you to define *how* the tokens are delivered (minted vs transferred).

## Features
* **Configurable Rate:** Set how many tokens 1 ETH buys.
* **Toggle:** Pause/Unpause sales easily.
* **Safety:** Abstract delivery method prevents logic errors.

## Integration

```solidity
import "../modules/CrowdsaleModule.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyICO is CrowdsaleModule, ERC20 {
    
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