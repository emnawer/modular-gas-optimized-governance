const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const Token = artifacts.require('Token');

contract('Token', function (accounts) {
    const [deployer, owner, custodian1, custodian2, custodian3, user1, user2] = accounts;
    const initialSupply = new BN('1000000000000000000000000'); // 1M tokens with 18 decimals
    const amount = new BN('1000000000000000000'); // 1 token with 18 decimals

    let token;
    let initialCustodians = [custodian1, custodian2, custodian3];

    beforeEach(async function () {
        token = await Token.new(initialCustodians, { from: deployer });
        await token.transfer(user1, amount, { from: deployer });
    });

    describe('Deployment', function () {
        it('should set the correct token name and symbol', async function () {
            expect(await token.name()).to.equal('Token');
            expect(await token.symbol()).to.equal('TKN');
        });

        it('should assign the total supply of tokens to the deployer', async function () {
            const deployerBalance = await token.balanceOf(deployer);
            expect(deployerBalance).to.be.bignumber.equal(initialSupply.sub(amount));
        });

        it('should set initial custodians correctly', async function () {
            for (const custodian of initialCustodians) {
                expect(await token.isCustodian(custodian)).to.be.true;
            }
        });
    });

    describe('Token transfers', function () {
        it('should transfer tokens between accounts', async function () {
            await token.transfer(user2, amount, { from: user1 });
            const user2Balance = await token.balanceOf(user2);
            expect(user2Balance).to.be.bignumber.equal(amount);
        });

        it('should fail if sender doesn\'t have enough tokens', async function () {
            const initialBalance = await token.balanceOf(user1);
            await expectRevert(
                token.transfer(user2, initialBalance.addn(1), { from: user1 }),
                'ERC20: transfer amount exceeds balance'
            );
        });

        it('should update balances after transfers', async function () {
            const initialDeployerBalance = await token.balanceOf(deployer);
            const initialUser1Balance = await token.balanceOf(user1);

            await token.transfer(user2, amount, { from: user1 });

            const finalDeployerBalance = await token.balanceOf(deployer);
            const finalUser1Balance = await token.balanceOf(user1);
            const user2Balance = await token.balanceOf(user2);

            expect(finalDeployerBalance).to.be.bignumber.equal(initialDeployerBalance);
            expect(finalUser1Balance).to.be.bignumber.equal(initialUser1Balance.sub(amount));
            expect(user2Balance).to.be.bignumber.equal(amount);
        });
    });

    describe('Blacklist functionality', function () {
        it('should allow owner to blacklist an address', async function () {
            await token.proposeBlacklistUpdate(user1, true, { from: custodian1 });
            // Simulate custodian voting (simplified - actual implementation depends on your governance)
            // This is a placeholder - you'll need to implement the actual voting mechanism
            // await token.vote(proposalId, true, { from: custodian2 });
            // await token.executeProposal(proposalId, { from: custodian1 });
            
            // After blacklisting, transfers from/to user1 should fail
            await expectRevert(
                token.transfer(user2, amount, { from: user1 }),
                'UserIsRestricted'
            );
            
            await expectRevert(
                token.transfer(user1, amount, { from: deployer }),
                'UserIsRestricted'
            );
        });

        it('should allow removing address from blacklist', async function () {
            // First blacklist
            await token.proposeBlacklistUpdate(user1, true, { from: custodian1 });
            // Simulate voting and execution...
            
            // Then remove from blacklist
            await token.proposeBlacklistUpdate(user1, false, { from: custodian1 });
            // Simulate voting and execution...
            
            // Transfers should work again
            await token.transfer(user2, amount, { from: user1 });
            const user2Balance = await token.balanceOf(user2);
            expect(user2Balance).to.be.bignumber.equal(amount);
        });
    });

    describe('Minting through governance', function () {
        it('should allow minting new tokens through governance', async function () {
            const initialSupply = await token.totalSupply();
            const mintAmount = new BN('500000000000000000000'); // 500 tokens
            
            await token.proposeMint(user1, mintAmount, { from: custodian1 });
            // Simulate voting and execution...
            
            const newSupply = await token.totalSupply();
            const user1Balance = await token.balanceOf(user1);
            
            expect(newSupply).to.be.bignumber.equal(initialSupply.add(mintAmount));
            expect(user1Balance).to.be.bignumber.equal(amount.add(mintAmount));
        });

        it('should not allow non-custodians to propose mints', async function () {
            await expectRevert(
                token.proposeMint(user1, amount, { from: user1 }),
                'Not a custodian'
            );
        });
    });

    describe('Ownership', function () {
        it('should allow owner to update metadata', async function () {
            await token.updateMetadata('New Token', 'NEW', { from: deployer });
            expect(await token.name()).to.equal('New Token');
            expect(await token.symbol()).to.equal('NEW');
        });

        it('should not allow non-owners to update metadata', async function () {
            await expectRevert(
                token.updateMetadata('Hacked', 'HACK', { from: user1 }),
                'Ownable: caller is not the owner'
            );
        });
    });

    describe('Rescue functionality', function () {
        it('should allow owner to rescue tokens', async function () {
            // This is a simplified test - actual implementation depends on your Rescuable contract
            // You'll need to send some ERC20 tokens to the contract first
            // Then test that the owner can rescue them
        });

        it('should not allow non-owners to rescue tokens', async function () {
            // Test that non-owners cannot call the rescue function
        });
    });
});