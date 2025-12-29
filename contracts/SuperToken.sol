// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

import "../modules/ERC20Combo.sol";
import "../modules/AccessControl.sol";
import "../modules/Security.sol";
import "../modules/Crowdsale.sol";
import "../modules/CustodianGovernance.sol";
import "../modules/GranularPausable.sol";
import "../modules/Timelock.sol";

/**
 * @title SuperToken
 * @notice The Ultimate Showcase of the Modular Governance Suite.
 * @dev Integrates AccessControl, Security, Crowdsale, Governance, Pausable, and Timelock.
 */
contract SuperToken is 
    ERC20Combo, 
    AccessControl, 
    UserStatus, 
    Rescuable, 
    Crowdsale, 
    CustodianGovernance,
    GranularPausable,
    Timelock 
{

    // ===========================================
    //             Role & Flag Constants
    // ===========================================
    uint256 public constant ROLE_ADMIN  = 1 << 0; 
    uint256 public constant ROLE_MINTER = 1 << 1; 

    uint256 public constant FLAG_BLACKLISTED = 1 << 0; 

    uint256 public constant PAUSE_TRANSFERS = 1 << 0; 
    uint256 public constant PAUSE_MINT      = 1 << 1; 

    // ===========================================
    //             Constructor
    // ===========================================
    constructor(address[] memory _initialCustodians) 
        ERC20Combo("SuperToken", "STKN") 
        CustodianGovernance(_initialCustodians) 
    {
        _grantRole(ROLE_ADMIN, msg.sender);
        tokensPerETH = 1000; 
        saleActive = true;
    }

    // ===========================================
    //             Core Token Overrides
    // ===========================================
    function _update(address from, address to, uint256 amount) internal override {
        // Check Pause
        if (from != address(0) && to != address(0)) {
            if (isFeaturePaused(PAUSE_TRANSFERS)) revert FeatureIsPaused(PAUSE_TRANSFERS);
        }

        // Check Blacklist
        if (from != address(0) && hasUserFlag(from, FLAG_BLACKLISTED)) {
            revert UserIsRestricted(from, FLAG_BLACKLISTED);
        }
        if (to != address(0) && hasUserFlag(to, FLAG_BLACKLISTED)) {
            revert UserIsRestricted(to, FLAG_BLACKLISTED);
        }

        super._update(from, to, amount);
    }

    // ===========================================
    //             Public Actions
    // ===========================================
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external onlyRole(ROLE_MINTER) whenNotPaused(PAUSE_MINT) {
        _mint(to, amount);
    }

    // ===========================================
    //             Admin Management
    // ===========================================
    function pauseFeature(uint256 flag) external onlyRole(ROLE_ADMIN) {
        _pauseFeature(flag);
    }

    function unpauseFeature(uint256 flag) external onlyRole(ROLE_ADMIN) {
        _unpauseFeature(flag);
    }

    function setBlacklistStatus(address account, bool status) external onlyRole(ROLE_ADMIN) {
        if (status) _setUserFlag(account, FLAG_BLACKLISTED);
        else _unsetUserFlag(account, FLAG_BLACKLISTED);
    }

    function updateMetadata(string memory _name, string memory _symbol) external onlyRole(ROLE_ADMIN) {
        name = _name;
        symbol = _symbol;
    }

    function grantRole(uint256 role, address account) external onlyRole(ROLE_ADMIN) {
        _grantRole(role, account);
    }

    function revokeRole(uint256 role, address account) external onlyRole(ROLE_ADMIN) {
        _revokeRole(role, account);
    }

    /**
     * @notice Allows Admin to update a custodian's role mask.
     * @dev Needed to fix the test case where custodian needs specific permission (4) to propose.
     */
    function setCustodianRole(address custodian, uint256 role) external onlyRole(ROLE_ADMIN) {
        _setCustodianRole(custodian, role);
    }

    // ===========================================
    //             Timelock Showcase
    // ===========================================
    bytes32 public constant HUGE_MINT_TYPE = keccak256("HUGE_MINT");

    function scheduleHugeMint(address to, uint256 amount) external onlyRole(ROLE_ADMIN) {
        bytes32 opId = keccak256(abi.encode(HUGE_MINT_TYPE, to, amount));
        _scheduleOperation(opId, 1 days);
    }

    function executeHugeMint(address to, uint256 amount) external onlyRole(ROLE_ADMIN) {
        bytes32 opId = keccak256(abi.encode(HUGE_MINT_TYPE, to, amount));
        _checkAndClearOperation(opId);
        _mint(to, amount);
    }

    // ===========================================
    //          Module Implementations
    // ===========================================
    function _checkSaleAuth() internal view override {
        _checkRole(ROLE_ADMIN);
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
        _mint(beneficiary, tokenAmount);
    }

    function _checkRescueAuth() internal view override {
        _checkRole(ROLE_ADMIN);
    }

    function _executeProposal(uint256 proposalId) internal override {
        Proposal storage p = proposals[proposalId];
        if (p.typeMask == (1 << 2)) {
            (address to, uint256 amount) = abi.decode(p.data, (address, uint256));
            _mint(to, amount);
        }
        else if (p.typeMask == (1 << 0)) {
            (address account,) = abi.decode(p.data, (address, bool));
            _setUserFlag(account, FLAG_BLACKLISTED);
        }
    }
}