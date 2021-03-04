const DigitalREToken = artifacts.require("DigitalREToken");
const truffleAssert = require("truffle-assertions");

contract("DigitalREToken", function (accounts) {

    describe("Initial deployment", async () => {
        it("should assert true", async function () {
            await DigitalREToken.deployed();
            assert.isTrue(true);
        });

        it("should initialize the owner as the supervisor", async () => {
            const DigitalRETokenInstance = await DigitalREToken.deployed();
            let supervisor = await DigitalRETokenInstance.supervisor.call();
            assert.equal(supervisor, accounts[0]);
        });
    });

    describe("addAsset", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        it("should not allow non supervisor to add an asset", async () => {
            // add asset by account 1 non supervisor
            const assetCountBefore = await DigitalRETokenInstance.getAssetsSize();
            await truffleAssert.reverts(DigitalRETokenInstance.addAsset(5, accounts[1], { from: accounts[2] }), 'Not A Supervisor');
            const assetCountAfter = await DigitalRETokenInstance.getAssetsSize();
            assert.isTrue(assetCountBefore.eq(assetCountAfter));
        });

        it("should allow supervisor to add assets ", async () => {
            // add asset by supervisor
            const assetCountBefore = await DigitalRETokenInstance.getAssetsSize();
            const tx1 = await DigitalRETokenInstance.addAsset(5, accounts[1], { from: accounts[0] });
            const tx2 = await DigitalRETokenInstance.addAsset(7, accounts[1], { from: accounts[0] });
            const tx3 = await DigitalRETokenInstance.addAsset(3, accounts[2], { from: accounts[0] });
            const assetCountAfter = await DigitalRETokenInstance.getAssetsSize();
            assert.equal(assetCountAfter.sub(assetCountBefore).toNumber(), 3);
            truffleAssert.eventEmitted(tx1, 'Transfer', (ev) => {
                return ev.from == 0 && ev.to === accounts[1] && ev.tokenId.toNumber() === 0;
            });
            truffleAssert.eventEmitted(tx2, 'Transfer', (ev) => {
                return ev.from == 0 && ev.to === accounts[1] && ev.tokenId.toNumber() === 1;
            });
            truffleAssert.eventEmitted(tx3, 'Transfer', (ev) => {
                return ev.from == 0 && ev.to === accounts[2] && ev.tokenId.toNumber() === 2;
            });
        });
    });

    describe("ownerOf", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        it("should fail to get the account address of non-existent asset", async () => {
            const assetId = 100;
            await truffleAssert.reverts(DigitalRETokenInstance.ownerOf(assetId), 'No Asset Exists');
        });

        it("should get the account address of asset", async () => {
            const asset0Owner = await DigitalRETokenInstance.ownerOf(0);
            const asset1Owner = await DigitalRETokenInstance.ownerOf(1);
            const asset2Owner = await DigitalRETokenInstance.ownerOf(2);
            assert.equal(asset0Owner, accounts[1]);
            assert.equal(asset1Owner, accounts[1]);
            assert.equal(asset2Owner, accounts[2]);
        });
    });

    describe("balanceOf", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        it("should get the balace of tokens owner account had", async () => {
            const ownedAssetsCount = await DigitalRETokenInstance.methods['balanceOf()']({ from: accounts[1] });
            assert.equal(ownedAssetsCount.toNumber(), 2);
        });
    });

    describe("build", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        it("Un approved owner should not be able to add build value to an asset", async () => {
            await truffleAssert.reverts(DigitalRETokenInstance.build(1, 2, { from: accounts[2] }), "Not An Approved owner");
        });

        it("approved owner should be able to add build value to an asset", async () => {
            await DigitalRETokenInstance.build(1, 2, { from: accounts[1] });
            const asset = await DigitalRETokenInstance.assetMap(1);
            assert.equal(asset.price, 9);
        });

    });

    describe("approve", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        it('Cannot approve someone for not your token', async () => {
            const assetId = 1;
            await truffleAssert.reverts(DigitalRETokenInstance.approve(accounts[2], assetId, { from: accounts[3] }), "NotTheAssetOwner");
        });

        it('Should fail to approve owner itself', async () => {
            const assetId = 1;
            await truffleAssert.reverts(DigitalRETokenInstance.approve(accounts[1], assetId, { from: accounts[1] }), "CurrentOwnerApproval");
        });

        it('Owner should be able to approve', async () => {
            const assetId = 1;
            const tx = await DigitalRETokenInstance.approve(accounts[2], assetId, { from: accounts[1] });
            let approved = await DigitalRETokenInstance.getApproved(assetId);
            assert.equal(approved, accounts[2]);
            truffleAssert.eventEmitted(tx, 'Approval', { owner: accounts[1], approved: accounts[2], tokenId: web3.utils.toBN(assetId) });
            truffleAssert.eventNotEmitted(tx, 'Transfer');
        });
    });

    describe("getApproved", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        it('Should faile to get approved account for a nonexistent asset', async () => {
            const assetId = 100;
            await truffleAssert.reverts(DigitalRETokenInstance.getApproved(assetId), 'Approved query for nonexistent token');
        });

        it('Should get the approved account of asset', async () => {
            const assetId = 1;
            let approved = await DigitalRETokenInstance.getApproved(assetId);
            assert.equal(approved, accounts[2]);
        });
    });

    describe("clearApproval", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        before(async () => {
            DigitalRETokenInstance = await DigitalREToken.deployed();
            const assetId = 2;
            await DigitalRETokenInstance.approve(accounts[3], assetId, { from: accounts[2] });
            let approved = await DigitalRETokenInstance.getApproved(assetId);
            assert.equal(approved, accounts[3]);
        });

        it('Should fail to clear approval by non-approved account', async () => {
            const assetId = 2;
            await truffleAssert.reverts(DigitalRETokenInstance.clearApproval(assetId, accounts[3], { from: accounts[0] }), 'Not An Approved Owner');
            let approved = await DigitalRETokenInstance.getApproved(assetId);
            assert.equal(approved, accounts[3]);
        });

        it('Should not change approval when try to clear approval of unapproved asset', async () => {
            const assetId = 0;
            await DigitalRETokenInstance.clearApproval(assetId, accounts[3], { from: accounts[1] })
            let approved = await DigitalRETokenInstance.getApproved(assetId);
            assert.equal(approved, 0);
        });

        it('Should be able to clear approval by owner', async () => {
            const assetId = 2;
            await DigitalRETokenInstance.clearApproval(assetId, accounts[3], { from: accounts[2] })
            let approved = await DigitalRETokenInstance.getApproved(assetId);
            assert.equal(approved, 0);
        });
    });

    describe("transferFrom", () => {
        let DigitalRETokenInstance;
        beforeEach(async () => {
            // get DigitalREToken
            DigitalRETokenInstance = await DigitalREToken.deployed();
        });

        it('Should fail to transfer for non approved account', async () => {
            const assetId = 1;
            await truffleAssert.reverts(DigitalRETokenInstance.methods['transferFrom(address,uint256)'](accounts[1], assetId, { from: accounts[3] }), "Not An Approved Owner");
        });

        it('Should fail to transfer with invalid from account', async () => {
            const assetId = 1;
            await truffleAssert.reverts(DigitalRETokenInstance.methods['transferFrom(address,uint256)'](accounts[0], assetId, { from: accounts[2] }), "Not The asset Owner");
        });

        it('Should fail to transfer without paying asset price', async () => {
            const assetId = 1;
            await truffleAssert.reverts(DigitalRETokenInstance.methods['transferFrom(address,uint256)'](accounts[1], assetId, { from: accounts[2] }));
        });

        it('Should fail to transfer with insufficient amount', async () => {
            const assetId = 1;
            await truffleAssert.reverts(DigitalRETokenInstance.methods['transferFrom(address,uint256)'](accounts[1], assetId, { from: accounts[2], value: web3.utils.toWei('2', 'ether') }));
        });

        it('Should be able to transfer with sufficient amount', async () => {
            const assetId = 1;
            const tx = await DigitalRETokenInstance.methods['transferFrom(address,uint256)'](accounts[1], assetId, { from: accounts[2], value: web3.utils.toWei('9', 'ether') });
            const asset1Owner = await DigitalRETokenInstance.ownerOf(1);
            assert.equal(asset1Owner, accounts[2]);
            truffleAssert.eventEmitted(tx, 'Transfer', { from: accounts[1], to: accounts[2], tokenId: web3.utils.toBN(assetId) });
            truffleAssert.eventNotEmitted(tx, 'Approval');
        });
    });

});