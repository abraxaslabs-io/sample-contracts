import { ethers } from "hardhat"
import { AddressLike, Signer } from "ethers"
import { expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { deployFixture } from "./fixtures/coreFixture"
import { SBTUpgradeable } from "./fixtures/coreFixture"

describe.only("SBT", function () {
  let admin: Signer
  let operator1: Signer
  let operator2: Signer
  let random: Signer
  let hhSBT: SBTUpgradeable

  before(async function () {
    const fixture = await loadFixture(deployFixture)
    admin = fixture.addr1
    operator1 = fixture.addr2
    operator2 = fixture.addr3
    random = fixture.addr8
    hhSBT = fixture.hhSBT
  })

  context("Deployment", function () {
    describe("SBT Contract", function () {
      before(async function () {
        //
      })

      it("version", async () => {
        expect(await hhSBT.version()).to.equal("1.0")
      })

      it("totalSupply", async () => {
        expect(await hhSBT.totalSupply()).to.equal(0)
      })

      it("nextTokenId", async () => {
        expect(await hhSBT.nextTokenId()).to.equal(1)
      })

      it("individualURI", async () => {
        expect(await hhSBT.individualURI()).to.equal(false)
      })

      it("baseURI", async () => {
        expect(await hhSBT.baseURI()).to.equal("https://something.com")
      })
    })
  })

  context("Configuration", function () {
    describe("setURI", function () {
      before(async function () {
        //
      })

      it("Random address cannot call", async () => {
        await expect(
          hhSBT.connect(random).setURI("something else"),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address cannot call", async () => {
        await expect(
          hhSBT.connect(admin).setURI("something else"),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Operator address 1 can call", async () => {
        await expect(hhSBT.connect(operator1).setURI("https://other.com")).to
          .not.be.reverted
      })

      it("URI is updated", async () => {
        expect(await hhSBT.baseURI()).to.equal("https://other.com")
      })

      it("Operator address 2 can call", async () => {
        await expect(hhSBT.connect(operator2).setURI("https://something.com"))
          .to.not.be.reverted
      })

      it("URI is updated", async () => {
        expect(await hhSBT.baseURI()).to.equal("https://something.com")
      })
    })
  })
})
