// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title ContractAccessControl
 * @notice A modular system to manage permissions using bitmask flags for maximum gas efficiency.
 * @dev Replaces nested mappings with uint256 bitmasks.
 * To use: Define constants in your contract:
 * uint256 constant ROLE_MINTER = 1 << 0; // 1
 * uint256 constant ROLE_ORACLE = 1 << 1; // 2
 * uint256 constant ROLE_ADMIN  = 1 << 2; // 4
 */
abstract contract ContractAccessControl {
    
    // Mapping from contract address => role bitmask
    // Example: 
    // Role A = 1 (Binary 001)
    // Role B = 2 (Binary 010)
    // User has Both = 3 (Binary 011)
    mapping(address => uint256) private _contractRoles;

    event ContractRoleGranted(uint256 indexed role, address indexed account);
    event ContractRoleRevoked(uint256 indexed role, address indexed account);

    error ContractMissingRole(address account, uint256 role);
    error InvalidContractAddress();

    /**
     * @dev Modifier that checks if the caller has the specific role flag.
     * @param role The bitmask flag required (e.g. 1, 2, 4, 8)
     */
    modifier onlyContractRole(uint256 role) {
        if ((_contractRoles[msg.sender] & role) != role) revert ContractMissingRole(msg.sender, role);
        _;
    }

    /**
     * @notice Checks if a contract has a specific role flag.
     */
    function hasContractRole(address account, uint256 role) public view returns (bool) {
        // Checks if ALL bits in 'role' are present in the user's mask
        return (_contractRoles[account] & role) == role;
    }

    /**
     * @dev Internal function to grant a role flag.
     * Uses bitwise OR (|=) to add the flag without removing others.
     */
    function _grantContractRole(uint256 role, address account) internal {
        if (account == address(0)) revert InvalidContractAddress();
        
        uint256 current = _contractRoles[account];
        // Only write to storage if the role isn't already there (saves gas)
        if ((current & role) != role) {
            _contractRoles[account] = current | role;
            emit ContractRoleGranted(role, account);
        }
    }

    /**
     * @dev Internal function to revoke a role flag.
     * Uses bitwise AND with NOT (&= ~) to remove only that flag.
     */
    function _revokeContractRole(uint256 role, address account) internal {
        uint256 current = _contractRoles[account];
        if ((current & role) == role) {
            _contractRoles[account] = current & ~role;
            emit ContractRoleRevoked(role, account);
        }
    }
}