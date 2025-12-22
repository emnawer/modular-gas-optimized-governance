// SPDX-License-Identifier: LGPL-2.1-or-later
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./modules/ContractAccessControl.sol";
import "./modules/SecurityModules.sol";
import "./modules/CrowdsaleModule.sol";

contract SuperToken is ERC20, ContractAccessControl, BitmaskUserStatus, Rescuable, CrowdsaleModule {
    // Roles
    uint256 public constant ROLE_ADMIN = 1 << 0;
    
    // Flags
    uint256 public constant FLAG_BLACKLISTED = 1 << 0;

    constructor() ERC20("Super", "SUP") {
        _grantContractRole(ROLE_ADMIN, msg.sender);
    }

    // Implementing Rescuable Auth
    function _checkRescueAuth() internal view override {
        // Use our bitmask role check
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

    // Overriding transfer to check Blacklist
    function _update(address from, address to, uint256 amount) internal override {
        // Bitmask check: Ensure 'from' and 'to' do NOT have the BLACKLISTED flag
        if (hasUserFlag(from, FLAG_BLACKLISTED)) revert UserIsRestricted(from, FLAG_BLACKLISTED);
        if (hasUserFlag(to, FLAG_BLACKLISTED)) revert UserIsRestricted(to, FLAG_BLACKLISTED);
        
        super._update(from, to, amount);
    }
}