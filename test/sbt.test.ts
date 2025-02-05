import { ethers } from "hardhat"
import { AddressLike, Signer } from "ethers"
import { expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { deployFixture } from "./fixtures/coreFixture"
import { SBTUpgradeable } from "./fixtures/coreFixture"

describe.only("SBT", function () {
  let addr1: Signer
  let addr2: Signer
  let addr3: Signer
  let addr8: Signer
  let address1: AddressLike
  let address2: AddressLike
  let hhSBT: SBTUpgradeable

  before(async function () {
    const fixture = await loadFixture(deployFixture)
    addr1 = fixture.addr1
    addr2 = fixture.addr2
    addr3 = fixture.addr3
    addr8 = fixture.addr8
    address1 = fixture.address1
    address2 = fixture.address2
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
})
