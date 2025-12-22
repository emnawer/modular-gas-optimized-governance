// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title CrowdsaleModule
 * @notice Adds a simple buyToken function.
 * @dev Implement _mint or transfer logic in the virtual function.
 */
abstract contract CrowdsaleModule {
    
    uint256 public tokensPerETH; // e.g., 1000 means 1 ETH = 1000 Tokens
    bool public saleActive;

    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event RateUpdated(uint256 newRate);
    event SaleStatusUpdated(bool status);

    error SaleNotActive();
    error InvalidEthAmount();

    /**
     * @dev Abstract function to deliver tokens (mint or transfer).
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual;
    
    /**
     * @dev Abstract function for auth check.
     */
    function _checkSaleAuth() internal virtual;

    function setSaleConfig(uint256 _rate, bool _active) external {
        _checkSaleAuth();
        tokensPerETH = _rate;
        saleActive = _active;
        emit RateUpdated(_rate);
        emit SaleStatusUpdated(_active);
    }

    function buyToken() external payable {
        if (!saleActive) revert SaleNotActive();
        if (msg.value == 0) revert InvalidEthAmount();

        // Calculate tokens: (ETH Wei * Rate)
        // If Rate is 1000 and msg.value is 1 ether (1e18):
        // 1e18 * 1000 = 1000 * 10^18 (1000 Tokens)
        uint256 tokenAmount = msg.value * tokensPerETH;

        _deliverTokens(msg.sender, tokenAmount);
        
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }
}