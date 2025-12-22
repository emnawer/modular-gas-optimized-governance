// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BitmaskUserStatus
 * @notice Manages user statuses (Blacklist, Freeze, etc.) using bitmasks for gas efficiency.
 * @dev Replaces multiple bool mappings with a single uint256 mapping.
 */
abstract contract BitmaskUserStatus {
    
    // Define your flags in the consuming contract or here
    // uint256 public constant FLAG_BLACKLISTED = 1 << 0; // 1
    // uint256 public constant FLAG_FROZEN      = 1 << 1; // 2
    // uint256 public constant FLAG_VIP         = 1 << 2; // 4

    mapping(address => uint256) private _userFlags;

    event UserFlagUpdated(address indexed user, uint256 flag, bool status);

    error UserIsRestricted(address user, uint256 flag);

    /**
     * @dev Modifier to ensure a user does NOT have a specific flag (e.g., not blacklisted).
     */
    modifier checkUserStatus(address user, uint256 flag) {
        if ((_userFlags[user] & flag) == flag) revert UserIsRestricted(user, flag);
        _;
    }

    function hasUserFlag(address user, uint256 flag) public view returns (bool) {
        return (_userFlags[user] & flag) == flag;
    }

    /**
     * @dev Internal function to set a flag (Enable).
     */
    function _setUserFlag(address user, uint256 flag) internal {
        uint256 current = _userFlags[user];
        if ((current & flag) != flag) {
            _userFlags[user] = current | flag;
            emit UserFlagUpdated(user, flag, true);
        }
    }

    /**
     * @dev Internal function to unset a flag (Disable).
     */
    function _unsetUserFlag(address user, uint256 flag) internal {
        uint256 current = _userFlags[user];
        if ((current & flag) == flag) {
            _userFlags[user] = current & ~flag;
            emit UserFlagUpdated(user, flag, false);
        }
    }
}

/**
 * @title Rescuable
 * @notice Standard logic to recover ETH and ERC20 tokens.
 */
abstract contract Rescuable {
    event ETHRecovered(address indexed to, uint256 amount);
    event ERC20Recovered(address indexed token, address indexed to, uint256 amount);

    error RescueTransferFailed();

    /**
     * @dev Abstract function: The consuming contract must define who can call this (e.g., Admin).
     */
    function _checkRescueAuth() internal virtual;

    function recoverETH(address payable to, uint256 amount) external {
        _checkRescueAuth();
        require(address(this).balance >= amount, "Insufficient ETH");
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert RescueTransferFailed();
        emit ETHRecovered(to, amount);
    }

    function recoverERC20(address token, address to, uint256 amount) external {
        _checkRescueAuth();
        bool success = IERC20(token).transfer(to, amount);
        if (!success) revert RescueTransferFailed();
        emit ERC20Recovered(token, to, amount);
    }
}