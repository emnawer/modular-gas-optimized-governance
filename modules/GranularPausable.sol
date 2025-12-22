// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title GranularPausable
 * @notice A module for pausing specific features of a contract independently.
 */
abstract contract GranularPausable {
    
    // Define the specific features you want to control
    // You can extend or change these in your implementation
    enum PauseFeature { 
        Update, 
        Permit, 
        Mint 
    }

    mapping(PauseFeature => bool) public featurePaused;

    event FeaturePaused(PauseFeature indexed feature, address account);
    event FeatureUnpaused(PauseFeature indexed feature, address account);

    error FeatureIsPaused(PauseFeature feature);

    /**
     * @dev Modifier to make a function callable only when a specific feature is NOT paused.
     */
    modifier whenNotPaused(PauseFeature feature) {
        if (featurePaused[feature]) {
            revert FeatureIsPaused(feature);
        }
        _;
    }

    /**
     * @dev Internal function to toggle state. 
     * Expose this via an access-controlled external function in your main contract.
     */
    function _setPause(PauseFeature feature, bool status) internal {
        featurePaused[feature] = status;
        if (status) {
            emit FeaturePaused(feature, msg.sender);
        } else {
            emit FeatureUnpaused(feature, msg.sender);
        }
    }
}