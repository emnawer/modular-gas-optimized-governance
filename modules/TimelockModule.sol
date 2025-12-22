// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title TimelockModule
 * @notice lightweight timelock mechanism for sensitive operations.
 */
abstract contract TimelockModule {
    
    mapping(bytes32 => uint256) private _timestamps;

    event OperationScheduled(bytes32 indexed opId, uint256 unlockTime);
    event OperationExecuted(bytes32 indexed opId);
    event OperationCancelled(bytes32 indexed opId);

    error OperationNotReady(uint256 unlockTime);
    error OperationNotScheduled();
    error OperationAlreadyExecuted();

    /**
     * @dev Schedule an operation.
     * @param opId Unique ID for the operation (usually keccak256(msg.data)).
     * @param delay Seconds to wait.
     */
    function _scheduleOperation(bytes32 opId, uint256 delay) internal {
        if (_timestamps[opId] != 0) revert OperationAlreadyExecuted(); // Prevent rescheduling active ops
        uint256 unlockTime = block.timestamp + delay;
        _timestamps[opId] = unlockTime;
        emit OperationScheduled(opId, unlockTime);
    }

    /**
     * @dev Check if an operation is ready and execute it (conceptually).
     * Consuming function should call this BEFORE executing the logic.
     */
    function _checkAndClearOperation(bytes32 opId) internal {
        uint256 unlockTime = _timestamps[opId];
        if (unlockTime == 0) revert OperationNotScheduled();
        if (block.timestamp < unlockTime) revert OperationNotReady(unlockTime);
        
        delete _timestamps[opId];
        emit OperationExecuted(opId);
    }

    function _cancelOperation(bytes32 opId) internal {
        delete _timestamps[opId];
        emit OperationCancelled(opId);
    }
}