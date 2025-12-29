// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title AccessControl
 * @notice A modular system to manage permissions using bitmask flags for maximum gas efficiency.
 * @dev Replaces nested mappings with uint256 bitmasks. Roles should be powers of 2 (1, 2, 4, 8...).
 */
abstract contract AccessControl {

    /// @dev Mapping from address => role bitmask
    mapping(address => uint256) private _roles;

    /// @notice Emitted when a role is granted to an account
    event RoleGranted(uint256 indexed role, address indexed account);

    /// @notice Emitted when a role is revoked from an account
    event RoleRevoked(uint256 indexed role, address indexed account);

    /// @notice Thrown when caller lacks the required role bitmask
    error MissingRole(address account, uint256 role);

    /// @notice Thrown when attempting to grant a role to the zero address
    error InvalidAddress();

    /**
     * @dev Modifier that checks if the caller has the specific role flag.
     * @param role The bitmask flag required (e.g. 1, 2, 4, 8).
     */
    modifier onlyRole(uint256 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev Internal helper to check if the caller has a role.
     * Can be used inside other functions (like overrides) without the modifier.
     * @param role The bitmask flag required.
     */
    function _checkRole(uint256 role) internal view {
        if ((_roles[msg.sender] & role) != role) revert MissingRole(msg.sender, role);
    }

    /**
     * @notice Checks if an account has a specific role flag.
     * @param account The address to check.
     * @param role The bitmask flag to verify.
     * @return True if the account possesses ALL bits in the role mask.
     */
    function hasRole(address account, uint256 role) public view returns (bool) {
        return (_roles[account] & role) == role;
    }

    /**
     * @dev Internal function to grant a role flag.
     * Uses bitwise OR (|=) to add the flag without removing others.
     * @param role The bitmask flag to grant.
     * @param account The address to receive the role.
     */
    function _grantRole(uint256 role, address account) internal {
        if (account == address(0)) revert InvalidAddress();

        uint256 current = _roles[account];
        // Only write to storage if the role isn't already there (saves gas)
        if ((current & role) != role) {
            _roles[account] = current | role;
            emit RoleGranted(role, account);
        }
    }

    /**
     * @dev Internal function to revoke a role flag.
     * Uses bitwise AND with NOT (&= ~) to remove only that flag.
     * @param role The bitmask flag to revoke.
     * @param account The address to lose the role.
     */
    function _revokeRole(uint256 role, address account) internal {
        uint256 current = _roles[account];
        if ((current & role) == role) {
            _roles[account] = current & ~role;
            emit RoleRevoked(role, account);
        }
    }
}