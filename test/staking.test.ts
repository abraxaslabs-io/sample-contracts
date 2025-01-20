import { ethers } from "hardhat"
import { AddressLike, Signer } from "ethers"
import { expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { deployFixture } from "./fixtures/coreFixture"
import { MockERC20, Staking } from "./fixtures/coreFixture"

describe("Staking", function () {
  let addr1: Signer
  let addr2: Signer
  let addr8: Signer
  let address1: AddressLike
  let address2: AddressLike
  let address8: AddressLike
  let hhMockERC20: MockERC20
  let hhStaking: Staking
  let hhMockERC20Address: AddressLike
  let hhStakingAddress: AddressLike
  let minStake: bigint
  let maxStake: bigint
  let durations: number[]

  before(async function () {
    const fixture = await loadFixture(deployFixture)
    addr1 = fixture.addr1
    addr2 = fixture.addr2
    addr8 = fixture.addr8
    address1 = fixture.address1
    address2 = fixture.address2
    address8 = fixture.address8
    hhMockERC20 = fixture.hhMockERC20
    hhStaking = fixture.hhStaking
    hhMockERC20Address = fixture.hhMockERC20Address
    hhStakingAddress = fixture.hhStakingAddress
    minStake = fixture.minStake
    maxStake = fixture.maxStake
    durations = fixture.durations
  })

  async function getCurrentBlockTime(): Promise<number> {
    const block = await ethers.provider.getBlock("latest")
    if (!block) {
      throw new Error("Failed to fetch the latest block.")
    }
    return block.timestamp
  }

  function addDays(timestamp: bigint, days: number): number {
    const additionalSeconds = days * 86400
    return Number(timestamp) + additionalSeconds
  }

  async function advanceBlockTime(days: number) {
    await ethers.provider.send("evm_increaseTime", [days * 86400])
    await ethers.provider.send("evm_mine", [])
  }

  context("Deployment", function () {
    describe("Staking Contract", function () {
      before(async function () {
        //
      })

      it("stakedToken", async () => {
        expect(await hhStaking.stakedToken()).to.equal(hhMockERC20Address)
      })

      it("minStakeAmount", async () => {
        expect(await hhStaking.minStakeAmount()).to.equal(minStake)
      })

      it("maxStakeAmount", async () => {
        expect(await hhStaking.maxStakeAmount()).to.equal(maxStake)
      })

      it("durations", async () => {
        expect(await hhStaking.isAllowedDuration(10)).to.equal(false)
        expect(await hhStaking.isAllowedDuration(20)).to.equal(false)
        expect(await hhStaking.isAllowedDuration(30)).to.equal(true)
        expect(await hhStaking.isAllowedDuration(45)).to.equal(false)
        expect(await hhStaking.isAllowedDuration(60)).to.equal(true)
        expect(await hhStaking.isAllowedDuration(80)).to.equal(false)
        expect(await hhStaking.isAllowedDuration(90)).to.equal(true)
        expect(await hhStaking.isAllowedDuration(99)).to.equal(false)
      })
    })
  })

  context("Staking", function () {
    describe("Staking Tokens", function () {
      before(async function () {
        //
      })

      it("Cannot stake unauthorised token", async () => {
        await expect(
          hhStaking.connect(addr1).stake(minStake, 90),
        ).to.be.revertedWithCustomError(
          hhMockERC20,
          "ERC20InsufficientAllowance",
        )
      })

      it("Can set allowance for staking contract", async () => {
        await expect(
          hhMockERC20
            .connect(addr1)
            .approve(hhStakingAddress, ethers.MaxUint256),
        ).to.not.be.reverted
      })

      it("Cannot stake below minimum", async () => {
        await expect(
          hhStaking.connect(addr1).stake(minStake - 1n, 90),
        ).to.be.revertedWith("Stake amount too low")
      })

      it("Cannot stake above maximum", async () => {
        await expect(
          hhStaking.connect(addr1).stake(maxStake + 1n, 90),
        ).to.be.revertedWith("Stake amount too high")
      })

      it("Cannot stake for invalid duration", async () => {
        await expect(
          hhStaking.connect(addr1).stake(minStake * 2n, 99),
        ).to.be.revertedWith("Invalid duration in days")
      })

      it("Can stake for minimum and valid duration", async () => {
        const preOwnerBalance = await hhMockERC20.balanceOf(address1)
        const preStakedBalance = await hhMockERC20.balanceOf(hhStaking)

        await expect(hhStaking.connect(addr1).stake(minStake, 90)).to.not.be
          .reverted

        const postOwnerBalance = await hhMockERC20.balanceOf(address1)
        const postStakedBalance = await hhMockERC20.balanceOf(hhStaking)

        expect(postStakedBalance).to.equal(preStakedBalance + minStake)
        expect(postOwnerBalance).to.equal(preOwnerBalance - minStake)
      })

      it("-> Stake recorded as expected", async () => {
        const ownerStakes = await hhStaking.allStakesForOwner(address1)
        const blockTime = await getCurrentBlockTime()

        expect(ownerStakes.length).to.equal(1)
        const s = ownerStakes[0]
        expect(s.amount).to.equal(minStake)
        expect(s.stakedTimestamp).to.equal(blockTime)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 90))
        expect(s.withdrawnTimestamp).to.equal(0)
      })

      it("Can stake for maximum and valid duration", async () => {
        await expect(hhStaking.connect(addr1).stake(maxStake, 90)).to.not.be
          .reverted
      })

      it("-> Stake recorded as expected", async () => {
        const ownerStakes = await hhStaking.allStakesForOwner(address1)
        const blockTime = await getCurrentBlockTime()

        expect(ownerStakes.length).to.equal(2)
        const s = ownerStakes[1]
        expect(s.amount).to.equal(maxStake)
        expect(s.stakedTimestamp).to.equal(blockTime)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 90))
        expect(s.withdrawnTimestamp).to.equal(0)
      })

      it("Can stake for other amount and valid duration", async () => {
        await expect(hhStaking.connect(addr1).stake(minStake * 5n, 90)).to.not
          .be.reverted
      })

      it("-> Stake recorded as expected", async () => {
        const ownerStakes = await hhStaking.allStakesForOwner(address1)
        const blockTime = await getCurrentBlockTime()

        expect(ownerStakes.length).to.equal(3)
        const s = ownerStakes[2]
        expect(s.amount).to.equal(minStake * 5n)
        expect(s.stakedTimestamp).to.equal(blockTime)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 90))
        expect(s.withdrawnTimestamp).to.equal(0)
      })

      it("Can stake for other other valid durations", async () => {
        await expect(hhStaking.connect(addr1).stake(minStake * 5n, 30)).to.not
          .be.reverted
      })

      it("-> Stake recorded as expected", async () => {
        const ownerStakes = await hhStaking.allStakesForOwner(address1)
        const blockTime = await getCurrentBlockTime()

        expect(ownerStakes.length).to.equal(4)
        const s = ownerStakes[3]
        expect(s.amount).to.equal(minStake * 5n)
        expect(s.stakedTimestamp).to.equal(blockTime)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 30))
        expect(s.withdrawnTimestamp).to.equal(0)
      })

      it("Can stake for other other valid durations", async () => {
        await expect(hhStaking.connect(addr1).stake(minStake * 5n, 60)).to.not
          .be.reverted
      })

      it("-> Stake recorded as expected", async () => {
        const ownerStakes = await hhStaking.allStakesForOwner(address1)
        const blockTime = await getCurrentBlockTime()

        expect(ownerStakes.length).to.equal(5)
        const s = ownerStakes[4]
        expect(s.amount).to.equal(minStake * 5n)
        expect(s.stakedTimestamp).to.equal(blockTime)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 60))
        expect(s.withdrawnTimestamp).to.equal(0)
      })

      it("Other owners can stake for valid durations", async () => {
        await expect(
          hhMockERC20
            .connect(addr2)
            .approve(hhStakingAddress, ethers.MaxUint256),
        ).to.not.be.reverted

        await expect(hhStaking.connect(addr2).stake(minStake * 5n, 60)).to.not
          .be.reverted
      })

      it("-> Stake recorded as expected", async () => {
        const ownerStakes = await hhStaking.allStakesForOwner(address2)
        const blockTime = await getCurrentBlockTime()

        expect(ownerStakes.length).to.equal(1)
        const s = ownerStakes[0]
        expect(s.amount).to.equal(minStake * 5n)
        expect(s.stakedTimestamp).to.equal(blockTime)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 60))
        expect(s.withdrawnTimestamp).to.equal(0)
      })
    })

    describe("View Methods", function () {
      before(async function () {
        //
      })

      it("allStakesForOwner", async () => {
        const ownerStakes = await hhStaking.allStakesForOwner(address2)
        const blockTime = await getCurrentBlockTime()

        expect(ownerStakes.length).to.equal(1)
        const s = ownerStakes[0]
        expect(s.amount).to.equal(minStake * 5n)
        expect(s.stakedTimestamp).to.equal(blockTime)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 60))
        expect(s.withdrawnTimestamp).to.equal(0)
      })

      it("allStakeOwners", async () => {
        const owners = await hhStaking.allStakeOwners()
        expect(owners.length).to.equal(2)
        expect(owners[0]).to.equal(address1)
        expect(owners[1]).to.equal(address2)
      })

      it("allStakes", async () => {
        const allStakes = await hhStaking.allStakes()
        expect(allStakes.length).to.equal(2)

        let o = allStakes[0]
        expect(o.owner).to.equal(address1)
        expect(o.stakes.length).to.equal(5)
        let s = o.stakes[0]
        expect(s.amount).to.equal(minStake)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 90))
        expect(s.withdrawnTimestamp).to.equal(0)
        s = o.stakes[4]
        expect(s.amount).to.equal(minStake * 5n)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 60))
        expect(s.withdrawnTimestamp).to.equal(0)
        o = allStakes[1]
        expect(o.owner).to.equal(address2)
        expect(o.stakes.length).to.equal(1)
        s = o.stakes[0]
        expect(s.amount).to.equal(minStake * 5n)
        expect(s.expiryTimestamp).to.equal(addDays(s.stakedTimestamp, 60))
        expect(s.withdrawnTimestamp).to.equal(0)
      })
    })

    describe("Unstaking Tokens", function () {
      before(async function () {
        //
      })

      it("Random cannot unstake before expiry", async () => {
        await expect(
          hhStaking.connect(addr8).unstake([
            {
              owner: address1,
              index: 0,
            },
          ]),
        ).to.be.revertedWith("Staking time has not yet expired")
      })

      it("Owner cannot unstake before expiry", async () => {
        await expect(
          hhStaking.connect(addr1).unstake([
            {
              owner: address1,
              index: 0,
            },
          ]),
        ).to.be.revertedWith("Staking time has not yet expired")
      })

      it("Can move forward 30 days", async () => {
        await advanceBlockTime(30)
      })

      it("Random can unstake expired stake", async () => {
        const preOwnerBalance = await hhMockERC20.balanceOf(address1)
        const preStakedBalance = await hhMockERC20.balanceOf(hhStaking)

        // Unstake the 30 days stake
        await expect(
          hhStaking.connect(addr8).unstake([
            {
              owner: address1,
              index: 3,
            },
          ]),
        ).to.not.be.reverted

        const postOwnerBalance = await hhMockERC20.balanceOf(address1)
        const postStakedBalance = await hhMockERC20.balanceOf(hhStaking)

        expect(postStakedBalance).to.equal(preStakedBalance - minStake * 5n)
        expect(postOwnerBalance).to.equal(preOwnerBalance + minStake * 5n)

        const blockTime = await getCurrentBlockTime()
        const ownerStakes = await hhStaking.allStakesForOwner(address1)
        const s = ownerStakes[3]
        expect(s.withdrawnTimestamp).to.equal(blockTime)
      })

      it("Cannot unstake expired stake twice", async () => {
        // Unstake the 30 days stake
        await expect(
          hhStaking.connect(addr8).unstake([
            {
              owner: address1,
              index: 3,
            },
          ]),
        ).to.be.revertedWith("Already unstaked")
      })

      it("Cannot unstake longer stakes that remain before expiry", async () => {
        await expect(
          hhStaking.connect(addr1).unstake([
            {
              owner: address1,
              index: 0,
            },
          ]),
        ).to.be.revertedWith("Staking time has not yet expired")
      })
    })
  })
})
