// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./modules/ContractAccessControl.sol";
import "./modules/SecurityModules.sol";
import "./modules/CrowdsaleModule.sol";
import "./modules/CustodianGovernance.sol";

/**
 * @title Hybrid Governance Token
 * @notice Combines fast owner actions with secure multi-signature governance for critical operations
 */
contract Token is ERC20, ContractAccessControl, BitmaskUserStatus, Rescuable, CrowdsaleModule, CustodianGovernance {
    // Roles
    uint256 public constant ROLE_ADMIN = 1 << 0;
    
    // Flags
    uint256 public constant FLAG_BLACKLISTED = 1 << 0;
    
    // Proposal Types (Bitmasks)
    uint256 public constant PROPOSAL_MINT = 1 << 0;
    uint256 public constant PROPOSAL_BLACKLIST = 1 << 1;
    uint256 public constant PROPOSAL_UPGRADE = 1 << 2;
    
    // State variables for pending actions
    address public pendingNewOwner;
    address public pendingBlacklistAddress;
    bool public pendingBlacklistStatus;
    
    /**
     * @dev Initialize the token with initial custodians
     * @param _initialCustodians Array of addresses that will be initial custodians
     */
    constructor(address[] memory _initialCustodians) 
        ERC20("Token", "TKN")
        CustodianGovernance(_initialCustodians)
    {
        _grantContractRole(ROLE_ADMIN, msg.sender);
        _transferOwnership(msg.sender);
    }

    // Implementing Rescuable Auth
    function _checkRescueAuth() internal view override {
        // Allow owner to rescue in emergency without governance delay
        if (msg.sender == owner()) {
            return;
        }
        // Otherwise check for admin role
        require(hasContractRole(msg.sender, ROLE_ADMIN), "No Admin Role");
    }

    // Implementing Crowdsale Delivery
    function _deliverTokens(address to, uint256 amount) internal override {
        _mint(to, amount);
    }
    
    // Implementing Crowdsale Auth
    function _checkSaleAuth() internal view override {
        require(hasContractRole(msg.sender, ROLE_ADMIN), "No Admin Role");
    }

    // ========== Governance-Controlled Functions ==========
    
    /**
     * @notice Propose a new mint operation (requires custodian approval)
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function proposeMint(address to, uint256 amount) external onlyCustodians {
        _submitProposal(PROPOSAL_MINT, abi.encode(to, amount), 0);
    }
    
    /**
     * @notice Propose to update blacklist status (requires custodian approval)
     * @param account Address to update
     * @param status True to blacklist, false to remove from blacklist
     */
    function proposeBlacklistUpdate(address account, bool status) external onlyCustodians {
        _submitProposal(PROPOSAL_BLACKLIST, abi.encode(account, status), 0);
    }
    
    // ========== Internal Overrides ==========
    
    /**
     * @dev Execute a proposal that has passed the voting period
     * @param proposalId The ID of the proposal to execute
     */
    function _executeProposal(uint256 proposalId) internal override {
        // Get proposal details
        (uint256 proposalType, bytes memory data, ) = getProposal(proposalId);
        
        if (proposalType == PROPOSAL_MINT) {
            (address to, uint256 amount) = abi.decode(data, (address, uint256));
            _mint(to, amount);
        } 
        else if (proposalType == PROPOSAL_BLACKLIST) {
            (address account, bool status) = abi.decode(data, (address, bool));
            if (status) {
                _setUserFlag(account, FLAG_BLACKLISTED, true);
            } else {
                _setUserFlag(account, FLAG_BLACKLISTED, false);
            }
        }
        
        // Call parent to clean up the proposal
        super._executeProposal(proposalId);
    }
    
    // Overriding transfer to check Blacklist
    function _update(address from, address to, uint256 amount) internal override {
        // Bitmask check: Ensure 'from' and 'to' do NOT have the BLACKLISTED flag
        if (hasUserFlag(from, FLAG_BLACKLISTED)) revert UserIsRestricted(from, FLAG_BLACKLISTED);
        if (hasUserFlag(to, FLAG_BLACKLISTED)) revert UserIsRestricted(to, FLAG_BLACKLISTED);
        
        super._update(from, to, amount);
    }
    
    // ========== Owner-Only Fast Actions ==========
    
    /**
     * @notice Fast action: Update token metadata (only owner, no governance delay)
     * @param name New token name
     * @param symbol New token symbol
     */
    function updateMetadata(string memory name, string memory symbol) external onlyOwner {
        // Implementation depends on your ERC20 implementation
        // This is a placeholder - you'll need to adjust based on your base ERC20 implementation
        // Some implementations may not support changing name/symbol after deployment
    }
}