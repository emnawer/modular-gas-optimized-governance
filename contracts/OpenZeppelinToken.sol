// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../modules/AccessControl.sol";
import "../modules/Security.sol";
import "../modules/Crowdsale.sol";
import "../modules/CustodianGovernance.sol";

/**
 * @title OpenZeppelin Governance Token Example
 * @notice Variant that showcases integrating CustodianGovernance with OpenZeppelin's Ownable helper.
 */
contract OpenZeppelinToken is
    ERC20,
    Ownable,
    AccessControl,
    UserStatus,
    Rescuable,
    Crowdsale,
    CustodianGovernance
{
    // Roles
    uint256 public constant ROLE_ADMIN = 1 << 0;
    uint256 public constant ROLE_CUSTODIAN = 1 << 1;

    // Flags
    uint256 public constant FLAG_BLACKLISTED = 1 << 0;

    // Proposal Types
    uint256 public constant PROPOSAL_MINT = 1 << 0;
    uint256 public constant PROPOSAL_BLACKLIST = 1 << 1;
    uint256 public constant PROPOSAL_UPGRADE = 1 << 2;
    uint256 public constant PROPOSAL_REPLACE_OWNER = 1 << 3;

    /**
     * @dev Initialize the token with initial custodians
     * @param _initialCustodians Array of addresses that will be initial custodians
     */
    constructor(address[] memory _initialCustodians)
        ERC20("Token", "TKN")
        CustodianGovernance(_initialCustodians)
    {
        _grantRole(ROLE_ADMIN, msg.sender);
        _transferOwnership(msg.sender);
    }

    // Implementing Rescuable Auth
    function _checkRescueAuth() internal view override {
        if (msg.sender == owner()) {
            return;
        }
        require(hasRole(msg.sender, ROLE_ADMIN), "No Admin Role");
    }

    // Implementing Crowdsale Delivery
    function _deliverTokens(address to, uint256 amount) internal override {
        _mint(to, amount);
    }

    // Implementing Crowdsale Auth
    function _checkSaleAuth() internal view override {
        require(hasRole(msg.sender, ROLE_ADMIN), "No Admin Role");
    }

    // ========== Governance-Controlled Functions ==========

    function proposeMint(address to, uint256 amount) external onlyRole(ROLE_CUSTODIAN) {
        _createProposal("Mint tokens", PROPOSAL_MINT, abi.encode(to, amount), 0);
    }

    function proposeBlacklistUpdate(address account, bool status) external onlyRole(ROLE_CUSTODIAN) {
        _createProposal(status ? "Blacklist account" : "Unblacklist account", PROPOSAL_BLACKLIST, abi.encode(account, status), 0);
    }

    function proposeReplaceOwner(address newOwner) external onlyRole(ROLE_CUSTODIAN) {
        _createProposal("Replace contract owner", PROPOSAL_REPLACE_OWNER, abi.encode(newOwner), 0);
    }

    // ========== Internal Overrides ==========

    function _executeProposal(uint256 proposalId) internal override {
        (uint256 proposalType, bytes memory data, ) = getProposal(proposalId);

        if (proposalType == PROPOSAL_MINT) {
            (address to, uint256 amount) = abi.decode(data, (address, uint256));
            _mint(to, amount);
        } else if (proposalType == PROPOSAL_BLACKLIST) {
            (address account, bool status) = abi.decode(data, (address, bool));
            if (status) {
                _setUserFlag(account, FLAG_BLACKLISTED);
            } else {
                _unsetUserFlag(account, FLAG_BLACKLISTED);
            }
        } else if (proposalType == PROPOSAL_REPLACE_OWNER) {
            address newOwner = abi.decode(data, (address));
            _transferOwnership(newOwner);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0) && hasUserFlag(from, FLAG_BLACKLISTED)) {
            revert UserIsRestricted(from, FLAG_BLACKLISTED);
        }
        if (to != address(0) && hasUserFlag(to, FLAG_BLACKLISTED)) {
            revert UserIsRestricted(to, FLAG_BLACKLISTED);
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    // ========== Owner-Only Fast Actions ==========

    function updateMetadata(string memory name, string memory symbol) external onlyOwner {
        // Placeholder for metadata updates. Most ERC20 implementations do not
        // allow changing name/symbol post-deployment without upgradeability.
    }
    
    // ========== Emergency Functions ==========
    
    function emergencyPause() external onlyOwner {
        _pause();
    }
    
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }
    
    function emergencyBurn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
    
    function emergencySetUserFlag(address account, uint256 flag) external onlyOwner {
        _setUserFlag(account, flag);
    }
    
    function emergencyUnsetUserFlag(address account, uint256 flag) external onlyOwner {
        _unsetUserFlag(account, flag);
    }
}
