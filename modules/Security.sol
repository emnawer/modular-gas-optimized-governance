// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

import "./IERC20Combo.sol";

/**
 * @title UserStatus
 * @notice Manages user statuses (Blacklist, Freeze, etc.) using bitmasks for gas efficiency.
 * @dev Replaces multiple bool mappings with a single uint256 mapping.
 */
abstract contract UserStatus {

    /// @dev Internal mapping of user addresses to their status flags
    mapping(address => uint256) private _userFlags;

    /// @notice Emitted when a user's flag status changes
    event UserFlagUpdated(address indexed user, uint256 flag, bool status);

    /// @notice Thrown when a user has a restricted flag (e.g. Blacklisted)
    error UserIsRestricted(address user, uint256 flag);

    /**
     * @dev Modifier to ensure a user does NOT have a specific flag.
     * @param user The address to check.
     * @param flag The flag that must NOT be present.
     */
    modifier checkUserStatus(address user, uint256 flag) {
        if ((_userFlags[user] & flag) == flag) revert UserIsRestricted(user, flag);
        _;
    }

    /**
     * @notice Public view to check if a user has a specific flag.
     * @param user The address to check.
     * @param flag The flag to verify.
     * @return True if the user has the flag.
     */
    function hasUserFlag(address user, uint256 flag) public view returns (bool) {
        return (_userFlags[user] & flag) == flag;
    }

    /**
     * @dev Internal function to set a flag (Enable).
     * @param user The user address.
     * @param flag The flag to add (power of 2).
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
     * @param user The user address.
     * @param flag The flag to remove.
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
 * @title ReentrancyGuard
 * @notice Contract module that helps prevent reentrant calls to a function.
 * @dev Based on OpenZeppelin's ReentrancyGuard but optimized for gas.
 */
abstract contract ReentrancyGuard {
    /// @dev Counter for reentrancy guard
    uint256 private _reentrancyGuard;

    /// @notice Error thrown when reentrancy is detected
    error ReentrantCall();

    /// @dev The default value for the reentrancy guard counter
    uint256 private constant _NOT_ENTERED = 1;
    /// @dev The value set when the function is entered
    uint256 private constant _ENTERED = 2;

    /**
     * @dev Modifier to prevent reentrancy
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_reentrancyGuard != _NOT_ENTERED) revert ReentrantCall();
        
        // Any calls to nonReentrant after this point will fail
        _reentrancyGuard = _ENTERED;
        _;
        
        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuard = _NOT_ENTERED;
    }
}

/**
 * @title Rescuable
 * @notice Standard logic to recover ETH and ERC20 tokens sent to the contract by mistake.
 */
abstract contract Rescuable {
    /// @notice Emitted when ETH is recovered
    event ETHRecovered(address indexed to, uint256 amount);
    /// @notice Emitted when ERC20 tokens are recovered
    event ERC20Recovered(address indexed token, address indexed to, uint256 amount);

    /// @notice Thrown if the recovery transfer fails
    error RescueTransferFailed();

    /**
     * @dev Abstract function: The consuming contract must define who can call this (e.g., Admin).
     */
    function _checkRescueAuth() internal virtual;

    /**
     * @notice Recover native ETH from the contract.
     * @param to The recipient address.
     * @param amount The amount of ETH (in wei).
     */
    function recoverETH(address payable to, uint256 amount) external {
        _checkRescueAuth();
        require(address(this).balance >= amount, "Insufficient ETH");
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert RescueTransferFailed();
        emit ETHRecovered(to, amount);
    }

    /**
     * @notice Recover any ERC20 token from the contract.
     * @param token The contract address of the token to recover.
     * @param to The recipient address.
     * @param amount The amount of tokens.
     */
    function recoverERC20(address token, address to, uint256 amount) external {
        _checkRescueAuth();
        bool success = IERC20Combo(token).transfer(to, amount);
        if (!success) revert RescueTransferFailed();
        emit ERC20Recovered(token, to, amount);
    }
}