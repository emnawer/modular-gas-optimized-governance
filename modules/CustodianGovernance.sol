// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CustodianGovernance
 * @notice A gas-optimized governance module with 2/3 consensus and bitmask roles.
 * @dev Supports typed proposals (e.g., Admin vs Financial) using bitmasks.
 */
abstract contract CustodianGovernance {
    
    // ===========================================
    //             State Variables
    // ===========================================
    
    // Role Bitmask: defines what permissions a custodian has.
    // e.g. 1 = General, 2 = Financial, 4 = Security
    mapping(address => uint256) public custodianRoles;
    
    // List used for Quorum calculation (Total Supply of voters)
    address[] public custodianList;
    
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 typeMask;   // Bitmask defining the proposal category
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // Proposal tracking
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    uint256 public constant QUORUM_NUMERATOR = 2;
    uint256 public constant QUORUM_DENOMINATOR = 3;

    // ===========================================
    //                Events
    // ===========================================
    event CustodianAdded(address indexed custodian, uint256 roles);
    event CustodianRemoved(address indexed custodian);
    event CustodianRoleUpdated(address indexed custodian, uint256 newRoles);
    event ProposalCreated(uint256 indexed id, uint256 typeMask, address indexed proposer);
    event VoteCast(uint256 indexed id, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed id, uint256 typeMask);

    // ===========================================
    //                Errors
    // ===========================================
    error NotCustodian();
    error UnauthorizedForProposalType(uint256 required, uint256 actual);
    error AlreadyCustodian();
    error ProposalNotFound();
    error AlreadyVoted();
    error ProposalAlreadyExecuted();
    error QuorumNotReached();

    // ===========================================
    //             Modifiers
    // ===========================================
    modifier onlyCustodian() {
        if (custodianRoles[msg.sender] == 0) revert NotCustodian();
        _;
    }

    // ===========================================
    //           Management Functions
    // ===========================================
    
    /**
     * @param _initialCustodians List of addresses to grant default role (1).
     */
    constructor(address[] memory _initialCustodians) {
        for (uint256 i = 0; i < _initialCustodians.length; i++) {
            _addCustodian(_initialCustodians[i], 1); // Default to Role 1
        }
    }

    function _addCustodian(address account, uint256 roles) internal {
        if (custodianRoles[account] != 0) revert AlreadyCustodian();
        custodianRoles[account] = roles;
        custodianList.push(account);
        emit CustodianAdded(account, roles);
    }

    function _setCustodianRole(address account, uint256 roles) internal {
        if (custodianRoles[account] == 0) revert NotCustodian();
        custodianRoles[account] = roles;
        emit CustodianRoleUpdated(account, roles);
    }

    /**
     * @notice Create a proposal with a specific type.
     * @param typeMask The category of the proposal (e.g., 1 for Admin). 
     * Proposer must possess this role bit to create it.
     */
    function createProposal(string calldata description, uint256 typeMask) external onlyCustodian returns (uint256) {
        // Optional: Require proposer to have the role they are proposing for?
        // Let's enforce: You can't propose a "Financial" change if you aren't a "Financial" custodian.
        if ((custodianRoles[msg.sender] & typeMask) != typeMask) {
            revert UnauthorizedForProposalType(typeMask, custodianRoles[msg.sender]);
        }

        uint256 id = proposalCount++;
        Proposal storage p = proposals[id];
        p.id = id;
        p.proposer = msg.sender;
        p.description = description;
        p.typeMask = typeMask;
        
        // Auto-vote yes
        p.yesVotes = 1;
        p.hasVoted[msg.sender] = true;
        
        emit ProposalCreated(id, typeMask, msg.sender);
        emit VoteCast(id, msg.sender, true);
        
        return id;
    }

    /**
     * @notice Vote on a proposal.
     * @dev Reverts if the voter does not have the bitmask role required by the proposal.
     */
    function vote(uint256 proposalId, bool support) external onlyCustodian {
        Proposal storage p = proposals[proposalId];
        if (p.proposer == address(0)) revert ProposalNotFound();
        if (p.executed) revert ProposalAlreadyExecuted();
        if (p.hasVoted[msg.sender]) revert AlreadyVoted();

        // Check Permissions: Does voter have the role required for this proposal type?
        if ((custodianRoles[msg.sender] & p.typeMask) != p.typeMask) {
            revert UnauthorizedForProposalType(p.typeMask, custodianRoles[msg.sender]);
        }

        p.hasVoted[msg.sender] = true;
        if (support) p.yesVotes++;
        else p.noVotes++;

        emit VoteCast(proposalId, msg.sender, support);

        // Check Execution (2/3 majority of ALL custodians)
        // Note: We calculate quorum based on TOTAL custodians, not just eligible ones.
        // This ensures a small subgroup cannot hijack the protocol.
        uint256 total = custodianList.length;
        if (total > 0 && (p.yesVotes * QUORUM_DENOMINATOR) >= (total * QUORUM_NUMERATOR)) {
            p.executed = true;
            _executeProposal(proposalId);
            emit ProposalExecuted(proposalId, p.typeMask);
        }
    }

    /**
     * @dev Abstract function to be implemented by the consuming contract.
     * Use logic like: if (proposals[id].typeMask == TYPE_ADMIN) ...
     */
    function _executeProposal(uint256 proposalId) internal virtual;
}