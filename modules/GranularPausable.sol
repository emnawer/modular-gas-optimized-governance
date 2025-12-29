// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title GranularPausable
 * @notice A gas-optimized module for pausing specific features using bitmasks.
 * @dev Replaces Enums/Mappings with a single uint256 bitmask.
 */
abstract contract GranularPausable {

    /// @dev Bitmask containing all currently paused flags
    uint256 private _pausedFlags;

    /// @notice Emitted when a specific feature flag is paused
    event FeaturePaused(uint256 indexed flag, address account);

    /// @notice Emitted when a specific feature flag is unpaused
    event FeatureUnpaused(uint256 indexed flag, address account);

    /// @notice Thrown when attempting to access a paused feature
    error FeatureIsPaused(uint256 flag);

    /**
     * @dev Modifier to make a function callable only when a specific flag is NOT paused.
     * @param flag The bitmask flag to check (e.g. 1, 2, 4).
     */
    modifier whenNotPaused(uint256 flag) {
        if ((_pausedFlags & flag) == flag) {
            revert FeatureIsPaused(flag);
        }
        _;
    }

    /**
     * @notice Check if a specific flag is currently paused.
     * @param flag The bitmask flag to check.
     */
    function isFeaturePaused(uint256 flag) public view returns (bool) {
        return (_pausedFlags & flag) == flag;
    }

    /**
     * @dev Internal function to pause a feature (Set bit to 1).
     * @param flag The bitmask flag to pause.
     */
    function _pauseFeature(uint256 flag) internal {
        uint256 current = _pausedFlags;
        if ((current & flag) != flag) {
            _pausedFlags = current | flag;
            emit FeaturePaused(flag, msg.sender);
        }
    }

    /**
     * @dev Internal function to unpause a feature (Set bit to 0).
     * @param flag The bitmask flag to unpause.
     */
    function _unpauseFeature(uint256 flag) internal {
        uint256 current = _pausedFlags;
        if ((current & flag) == flag) {
            _pausedFlags = current & ~flag;
            emit FeatureUnpaused(flag, msg.sender);
        }
    }
}