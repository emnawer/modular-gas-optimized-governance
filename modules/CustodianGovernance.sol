// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

/**
 * @title CustodianGovernance
 * @notice A module for custom multi-signature governance with 2/3 consensus.
 * @dev This is an example of "Rolling your own crypto" governance. 
 * For production, consider Gnosis Safe or OpenZeppelin Governance.
 */
abstract contract CustodianGovernance {
    
    // ===========================================
    //             State Variables
    // ===========================================
    struct Custodian {
        address addr;
        string name;
        uint256 id;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(address => bool) public isCustodian;
    address[] public custodianList;
    
    // Proposal tracking
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    uint256 public constant QUORUM_NUMERATOR = 2;
    uint256 public constant QUORUM_DENOMINATOR = 3;

    // ===========================================
    //                Events
    // ===========================================
    event CustodianAdded(address indexed custodian);
    event CustodianRemoved(address indexed custodian);
    event ProposalCreated(uint256 indexed id, address indexed proposer, string desc);
    event VoteCast(uint256 indexed id, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed id);

    // ===========================================
    //                Errors
    // ===========================================
    error NotCustodian();
    error AlreadyCustodian();
    error ProposalNotFound();
    error AlreadyVoted();
    error ProposalAlreadyExecuted();
    error QuorumNotReached();

    // ===========================================
    //             Modifiers
    // ===========================================
    modifier onlyCustodian() {
        if (!isCustodian[msg.sender]) revert NotCustodian();
        _;
    }

    // ===========================================
    //           Management Functions
    // ===========================================
    
    constructor(address[] memory _initialCustodians) {
        for (uint256 i = 0; i < _initialCustodians.length; i++) {
            _addCustodian(_initialCustodians[i]);
        }
    }

    function _addCustodian(address account) internal {
        if (isCustodian[account]) revert AlreadyCustodian();
        isCustodian[account] = true;
        custodianList.push(account);
        emit CustodianAdded(account);
    }

    function createProposal(string calldata description) external onlyCustodian returns (uint256) {
        uint256 id = proposalCount++;
        Proposal storage p = proposals[id];
        p.id = id;
        p.proposer = msg.sender;
        p.description = description;
        // Auto-vote yes
        p.yesVotes = 1;
        p.hasVoted[msg.sender] = true;
        
        emit ProposalCreated(id, msg.sender, description);
        emit VoteCast(id, msg.sender, true);
        
        return id;
    }

    function vote(uint256 proposalId, bool support) external onlyCustodian {
        Proposal storage p = proposals[proposalId];
        if (p.proposer == address(0)) revert ProposalNotFound();
        if (p.executed) revert ProposalAlreadyExecuted();
        if (p.hasVoted[msg.sender]) revert AlreadyVoted();

        p.hasVoted[msg.sender] = true;
        if (support) p.yesVotes++;
        else p.noVotes++;

        emit VoteCast(proposalId, msg.sender, support);

        // Check Execution (2/3 majority)
        uint256 total = custodianList.length;
        if (total > 0 && (p.yesVotes * QUORUM_DENOMINATOR) >= (total * QUORUM_NUMERATOR)) {
            p.executed = true;
            _executeProposal(proposalId);
            emit ProposalExecuted(proposalId);
        }
    }

    /**
     * @dev Abstract function to be implemented by the consuming contract.
     * Define what happens when a proposal passes.
     */
    function _executeProposal(uint256 proposalId) internal virtual;
}