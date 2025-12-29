// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title IERC20Combo
 * @notice Interface describing the gas-optimized ERC20 with built-in EIP-2612 permit support.
 * @dev Mirrors the external/public surface exposed by OptimizedERC20 implementations within this repo.
 */
interface IERC20Combo {
    // --------------------------
    // Metadata
    // --------------------------
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);

    // --------------------------
    // ERC20 Views
    // --------------------------
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    // --------------------------
    // ERC20 Actions
    // --------------------------
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // --------------------------
    // EIP-2612 Permit
    // --------------------------
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // --------------------------
    // Events
    // --------------------------
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
