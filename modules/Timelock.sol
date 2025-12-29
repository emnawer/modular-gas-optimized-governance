// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title Timelock
 * @notice Lightweight timelock mechanism for sensitive operations.
 * @dev Implements a Schedule-Wait-Execute pattern.
 */
abstract contract Timelock {
    
    /// @dev Maps operation ID to the timestamp when it can be executed
    mapping(bytes32 => uint256) private _timestamps;

    /// @notice Emitted when an operation is scheduled
    event OperationScheduled(bytes32 indexed opId, uint256 unlockTime);
    /// @notice Emitted when an operation is executed
    event OperationExecuted(bytes32 indexed opId);
    /// @notice Emitted when an operation is cancelled
    event OperationCancelled(bytes32 indexed opId);

    /// @notice Thrown when attempting to execute before the delay has passed
    error OperationNotReady(uint256 unlockTime);
    /// @notice Thrown when attempting to execute an unknown operation
    error OperationNotScheduled();
    /// @notice Thrown when scheduling an ID that is already pending
    error OperationAlreadyExecuted();

    /**
     * @dev Schedule an operation for future execution.
     * @param opId Unique ID for the operation (typically `keccak256(abi.encode(...))`).
     * @param delay Seconds to wait before execution is allowed.
     */
    function _scheduleOperation(bytes32 opId, uint256 delay) internal {
        if (_timestamps[opId] != 0) revert OperationAlreadyExecuted(); 
        uint256 unlockTime = block.timestamp + delay;
        _timestamps[opId] = unlockTime;
        emit OperationScheduled(opId, unlockTime);
    }

    /**
     * @dev Check if an operation is ready and clear it from the schedule.
     * @notice Consuming function should call this BEFORE executing the logic.
     * @param opId The unique ID of the operation.
     */
    function _checkAndClearOperation(bytes32 opId) internal {
        uint256 unlockTime = _timestamps[opId];
        if (unlockTime == 0) revert OperationNotScheduled();
        if (block.timestamp < unlockTime) revert OperationNotReady(unlockTime);
        
        delete _timestamps[opId];
        emit OperationExecuted(opId);
    }

    /**
     * @dev Cancel a pending operation.
     * @param opId The unique ID of the operation to cancel.
     */
    function _cancelOperation(bytes32 opId) internal {
        delete _timestamps[opId];
        emit OperationCancelled(opId);
    }
}