// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title Crowdsale
 * @notice Abstract base for direct ETH-to-Token sales.
 * @dev Handles exchange rate calculation and sale status. Token delivery is abstract.
 */
abstract contract Crowdsale {

    /// @notice How many tokens a user gets per 1 ETH
    uint256 public tokensPerETH; 

    /// @notice Whether the sale is currently accepting payments (pausable)
    bool public saleActive;

    /// @notice Emitted when tokens are purchased
    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);

    /// @notice Emitted when the exchange rate changes
    event RateUpdated(uint256 newRate);

    /// @notice Emitted when the sale is paused or unpaused
    event SaleStatusUpdated(bool status);

    /// @notice Thrown if attempting to buy when sale is paused
    error SaleNotActive();
    /// @notice Thrown if sending 0 ETH
    error InvalidEthAmount();

    /**
     * @dev Abstract function to deliver tokens (mint or transfer).
     * @param beneficiary The address receiving the tokens.
     * @param tokenAmount The calculated amount of tokens to send.
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual;

    /**
     * @dev Abstract function for auth check on admin functions.
     */
    function _checkSaleAuth() internal virtual;

    /**
     * @notice Admin function to configure sale parameters.
     * @param _rate The new exchange rate (Tokens per ETH).
     * @param _active The new status of the sale.
     */
    function setSaleConfig(uint256 _rate, bool _active) external {
        _checkSaleAuth();
        tokensPerETH = _rate;
        saleActive = _active;
        emit RateUpdated(_rate);
        emit SaleStatusUpdated(_active);
    }

    /**
     * @notice Public function to purchase tokens with ETH.
     * @dev Reverts if sale is not active or 0 ETH is sent.
     */
    function buyToken() external payable {
        if (!saleActive) revert SaleNotActive();
        if (msg.value == 0) revert InvalidEthAmount();

        // Calculate tokens: (ETH Wei * Rate)
        uint256 tokenAmount = msg.value * tokensPerETH;

        _deliverTokens(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }
}