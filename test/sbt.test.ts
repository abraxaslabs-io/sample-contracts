import { upgrades } from "hardhat"
import { AddressLike, Signer } from "ethers"
import { expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { deployFixture } from "./fixtures/coreFixture"
import { SBTUpgradeable } from "./fixtures/coreFixture"

describe.only("SBT", function () {
  let owner: Signer
  let admin1: Signer
  let admin1Addr: AddressLike
  let admin2: Signer
  let upgradeAdmin: Signer
  let superUser: Signer
  let superUserAddr: AddressLike
  let holder1: AddressLike
  let holder2: AddressLike
  let holder3: AddressLike
  let holder4: AddressLike
  let holder5: AddressLike
  let holder6: AddressLike
  let standardUser: Signer
  let standardUserAddr: AddressLike
  let random: Signer
  let hhSBT: SBTUpgradeable
  let hhSBTUpgrade: SBTUpgradeable

  before(async function () {
    const fixture = await loadFixture(deployFixture)
    owner = fixture.addr1
    admin1 = fixture.addr2
    admin1Addr = await admin1.getAddress()
    admin2 = fixture.addr3
    upgradeAdmin = fixture.addr4
    superUser = fixture.addr5
    superUserAddr = await superUser.getAddress()
    standardUser = fixture.addr6
    standardUserAddr = await standardUser.getAddress()
    random = fixture.addr8
    hhSBT = fixture.hhSBT
    hhSBTUpgrade = fixture.hhSBTUpgrade
    holder1 = await (fixture.addrs[0] as Signer).getAddress()
    holder2 = await (fixture.addrs[1] as Signer).getAddress()
    holder3 = await (fixture.addrs[2] as Signer).getAddress()
    holder4 = await (fixture.addrs[3] as Signer).getAddress()
    holder5 = await (fixture.addrs[4] as Signer).getAddress()
    holder6 = await (fixture.addrs[5] as Signer).getAddress()
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
        expect(await hhSBT.individualURI()).to.equal(true)
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

      it("Owner address cannot call", async () => {
        await expect(
          hhSBT.connect(owner).setURI("something else"),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address 1 can call", async () => {
        await expect(hhSBT.connect(admin1).setURI("https://other.com")).to.not
          .be.reverted
      })

      it("URI is updated", async () => {
        expect(await hhSBT.baseURI()).to.equal("https://other.com")
      })

      it("Admin address 2 can call", async () => {
        await expect(hhSBT.connect(admin2).setURI("https://something.com")).to
          .not.be.reverted
      })

      it("URI is updated", async () => {
        expect(await hhSBT.baseURI()).to.equal("https://something.com")
      })
    })

    describe("setIndividualURI", function () {
      before(async function () {
        //
      })

      it("individualURI is true", async () => {
        expect(await hhSBT.individualURI()).to.equal(true)
      })

      it("Random address cannot call", async () => {
        await expect(
          hhSBT.connect(random).setIndividualURI(false),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Owner address cannot call", async () => {
        await expect(
          hhSBT.connect(owner).setIndividualURI(false),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address 1 can call", async () => {
        await expect(hhSBT.connect(admin1).setIndividualURI(false)).to.not.be
          .reverted
      })

      it("individualURI is updated", async () => {
        expect(await hhSBT.individualURI()).to.equal(false)
      })

      it("Admin address 2 can call", async () => {
        await expect(hhSBT.connect(admin2).setIndividualURI(true)).to.not.be
          .reverted
      })

      it("individualURI is updated", async () => {
        expect(await hhSBT.individualURI()).to.equal(true)
      })
    })

    describe("setUpgradeApproved", function () {
      before(async function () {
        //
      })

      it("upgradeApproved is false", async () => {
        expect(await hhSBT.upgradeApproved()).to.equal(false)
      })

      it("Random address cannot call", async () => {
        await expect(
          hhSBT.connect(random).setUpgradeApproved(true),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address 1 cannot call", async () => {
        await expect(
          hhSBT.connect(admin1).setUpgradeApproved(true),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address 2 cannot call", async () => {
        await expect(
          hhSBT.connect(admin1).setUpgradeApproved(true),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Owner address can call", async () => {
        await expect(hhSBT.connect(owner).setUpgradeApproved(true)).to.not.be
          .reverted
      })

      it("upgradeApproved is true", async () => {
        expect(await hhSBT.upgradeApproved()).to.equal(true)

        await expect(hhSBT.connect(owner).setUpgradeApproved(false)).to.not.be
          .reverted
      })
    })
  })

  context("Token Operations", function () {
    describe("batchMint", function () {
      before(async function () {
        //
      })

      it("Random address cannot call", async () => {
        await expect(
          hhSBT.connect(random).batchMint([holder1, holder2]),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Owner address cannot call", async () => {
        await expect(
          hhSBT.connect(random).batchMint([holder1, holder2]),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address 1 can call", async () => {
        await expect(hhSBT.connect(admin1).batchMint([holder1, holder2])).to.not
          .be.reverted
      })

      it("Tokens are minted", async () => {
        expect(await hhSBT.totalSupply()).to.equal(2)
        expect(await hhSBT.ownerOf(1)).to.equal(holder1)
        expect(await hhSBT.ownerOf(2)).to.equal(holder2)
        expect(await hhSBT.balanceOf(holder1)).to.equal(1)
        expect(await hhSBT.balanceOf(holder2)).to.equal(1)
        expect(await hhSBT.tokenOfOwnerByIndex(holder1, 0)).to.equal(1)
        expect(await hhSBT.tokenOfOwnerByIndex(holder2, 0)).to.equal(2)
      })

      it("Admin address 2 can call", async () => {
        await expect(hhSBT.connect(admin1).batchMint([holder2, holder3])).to.not
          .be.reverted
      })

      it("Tokens are minted", async () => {
        expect(await hhSBT.totalSupply()).to.equal(4)
        expect(await hhSBT.ownerOf(3)).to.equal(holder2)
        expect(await hhSBT.ownerOf(4)).to.equal(holder3)
        expect(await hhSBT.balanceOf(holder2)).to.equal(2)
        expect(await hhSBT.balanceOf(holder3)).to.equal(1)
        expect(await hhSBT.tokenOfOwnerByIndex(holder2, 0)).to.equal(2)
        expect(await hhSBT.tokenOfOwnerByIndex(holder2, 1)).to.equal(3)
        expect(await hhSBT.tokenOfOwnerByIndex(holder3, 0)).to.equal(4)
      })
    })

    describe("batchBurn", function () {
      before(async function () {
        //
      })

      it("Random address cannot call", async () => {
        await expect(
          hhSBT.connect(random).batchBurn([1, 2]),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Owner address cannot call", async () => {
        await expect(
          hhSBT.connect(random).batchBurn([1, 2]),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address 1 can call", async () => {
        await expect(hhSBT.connect(admin1).batchBurn([1, 2])).to.not.be.reverted
      })

      it("Tokens are burned", async () => {
        expect(await hhSBT.totalSupply()).to.equal(2)
        expect(await hhSBT.balanceOf(holder1)).to.equal(0)
        expect(await hhSBT.balanceOf(holder2)).to.equal(1)
        expect(await hhSBT.tokenOfOwnerByIndex(holder2, 0)).to.equal(3)
      })

      it("Admin address 2 can call", async () => {
        await expect(hhSBT.connect(admin1).batchBurn([3, 4])).to.not.be.reverted
      })

      it("Tokens are burned", async () => {
        expect(await hhSBT.totalSupply()).to.equal(0)
        expect(await hhSBT.balanceOf(holder2)).to.equal(0)
        expect(await hhSBT.balanceOf(holder3)).to.equal(0)
      })
    })

    describe("batchTransfer", function () {
      interface Transfer {
        tokenId: number
        from: AddressLike
        to: AddressLike
      }
      let transfer1: Transfer
      let transfer2: Transfer
      let transfer3: Transfer
      let transfer4: Transfer

      before(async function () {
        transfer1 = {
          tokenId: 5,
          from: holder1,
          to: holder4,
        }
        transfer2 = {
          tokenId: 6,
          from: holder2,
          to: holder4,
        }
        transfer3 = {
          tokenId: 7,
          from: holder2,
          to: holder4,
        }
        transfer4 = {
          tokenId: 8,
          from: holder2,
          to: holder4,
        }

        await expect(
          hhSBT.connect(admin1).batchMint([holder1, holder2, holder2, holder2]),
        ).to.not.be.reverted
        expect(await hhSBT.totalSupply()).to.equal(4)
        expect(await hhSBT.balanceOf(holder1)).to.equal(1)
        expect(await hhSBT.balanceOf(holder2)).to.equal(3)
      })

      it("Random address cannot call", async () => {
        await expect(
          hhSBT.connect(random).batchTransfer([transfer1, transfer2]),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Owner address cannot call", async () => {
        await expect(
          hhSBT.connect(random).batchTransfer([transfer1, transfer2]),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin address 1 can call", async () => {
        await expect(
          hhSBT.connect(admin1).batchTransfer([transfer1, transfer2]),
        ).to.not.be.reverted
      })

      it("Tokens are transferred", async () => {
        expect(await hhSBT.totalSupply()).to.equal(4)
        expect(await hhSBT.balanceOf(holder1)).to.equal(0)
        expect(await hhSBT.balanceOf(holder2)).to.equal(2)
        expect(await hhSBT.balanceOf(holder4)).to.equal(2)
        expect(await hhSBT.ownerOf(5)).to.equal(holder4)
        expect(await hhSBT.ownerOf(6)).to.equal(holder4)
        expect(await hhSBT.ownerOf(7)).to.equal(holder2)
        expect(await hhSBT.ownerOf(8)).to.equal(holder2)
      })

      it("Admin address 2 can call", async () => {
        await expect(
          hhSBT.connect(admin1).batchTransfer([transfer3, transfer4]),
        ).to.not.be.reverted
      })

      it("Tokens are transferred", async () => {
        expect(await hhSBT.totalSupply()).to.equal(4)
        expect(await hhSBT.balanceOf(holder1)).to.equal(0)
        expect(await hhSBT.balanceOf(holder2)).to.equal(0)
        expect(await hhSBT.balanceOf(holder4)).to.equal(4)
        expect(await hhSBT.ownerOf(5)).to.equal(holder4)
        expect(await hhSBT.ownerOf(6)).to.equal(holder4)
        expect(await hhSBT.ownerOf(7)).to.equal(holder4)
        expect(await hhSBT.ownerOf(8)).to.equal(holder4)
      })
    })
  })

  context("Token URI", function () {
    describe("Single URI for all tokens", function () {
      it("URI is as expected", async () => {
        await expect(hhSBT.connect(admin1).setIndividualURI(false)).to.not.be
          .reverted
        expect(await hhSBT.tokenURI(5)).to.equal("https://something.com")
        expect(await hhSBT.tokenURI(6)).to.equal("https://something.com")
        expect(await hhSBT.tokenURI(7)).to.equal("https://something.com")
      })
    })
    describe("Token specific URI for all tokens", function () {
      it("URI is as expected", async () => {
        await expect(hhSBT.connect(admin1).setIndividualURI(true)).to.not.be
          .reverted
        expect(await hhSBT.tokenURI(5)).to.equal("https://something.com/5")
        expect(await hhSBT.tokenURI(6)).to.equal("https://something.com/6")
        expect(await hhSBT.tokenURI(7)).to.equal("https://something.com/7")
      })
    })
  })

  context("User Operations", function () {
    describe("setApprovalForAll", function () {
      it("Standard user cannot", async () => {
        await expect(
          hhSBT.connect(random).setApprovalForAll(holder1, true),
        ).to.be.revertedWith("Insufficient authority")
      })

      it("Admin user can", async () => {
        await expect(hhSBT.connect(admin1).setApprovalForAll(holder1, true)).to
          .not.be.reverted
      })

      it("Super user can", async () => {
        await expect(hhSBT.connect(superUser).setApprovalForAll(holder1, true))
          .to.not.be.reverted
      })
    })

    describe("transfer", function () {
      before(async function () {
        await expect(
          hhSBT.connect(admin1).batchMint([
            standardUserAddr, // 9
            superUserAddr, // 10
            superUserAddr, //11
            admin1Addr, // 12
            admin1Addr, // 13
          ]),
        ).to.not.be.reverted

        expect(await hhSBT.balanceOf(standardUserAddr)).to.equal(1)
        expect(await hhSBT.balanceOf(admin1Addr)).to.equal(2)
        expect(await hhSBT.balanceOf(superUserAddr)).to.equal(2)
        expect(await hhSBT.balanceOf(holder5)).to.equal(0)
      })

      it("Standard user cannot", async () => {
        await expect(
          hhSBT
            .connect(standardUser)
            .transferFrom(standardUserAddr, holder5, 9),
        ).to.be.revertedWith("Insufficient authority")
      })

      it("Admin user can", async () => {
        await expect(
          hhSBT.connect(admin1).transferFrom(admin1Addr, holder5, 12),
        ).to.not.be.reverted
      })

      it("Tokens is transferred", async () => {
        expect(await hhSBT.balanceOf(standardUserAddr)).to.equal(1)
        expect(await hhSBT.balanceOf(admin1Addr)).to.equal(1)
        expect(await hhSBT.balanceOf(superUserAddr)).to.equal(2)
        expect(await hhSBT.balanceOf(holder5)).to.equal(1)
        expect(await hhSBT.ownerOf(12)).to.equal(holder5)
      })

      it("Super user can", async () => {
        await expect(
          hhSBT.connect(superUser).transferFrom(superUserAddr, holder6, 10),
        ).to.not.be.reverted
      })

      it("Tokens is transferred", async () => {
        expect(await hhSBT.balanceOf(standardUserAddr)).to.equal(1)
        expect(await hhSBT.balanceOf(admin1Addr)).to.equal(1)
        expect(await hhSBT.balanceOf(superUserAddr)).to.equal(1)
        expect(await hhSBT.balanceOf(holder5)).to.equal(1)
        expect(await hhSBT.balanceOf(holder6)).to.equal(1)
        expect(await hhSBT.ownerOf(10)).to.equal(holder6)
      })

      it("Super user cannot transfer others", async () => {
        await expect(
          hhSBT.connect(superUser).transferFrom(standardUserAddr, holder6, 9),
        ).to.be.revertedWithCustomError(hhSBT, "ERC721InsufficientApproval")
      })
    })

    describe("burn", function () {
      before(async function () {
        expect(await hhSBT.balanceOf(standardUserAddr)).to.equal(1)
        expect(await hhSBT.balanceOf(admin1Addr)).to.equal(1)
        expect(await hhSBT.balanceOf(superUserAddr)).to.equal(1)
        expect(await hhSBT.balanceOf(holder5)).to.equal(1)
        expect(await hhSBT.balanceOf(holder6)).to.equal(1)
      })

      it("Standard user cannot", async () => {
        await expect(hhSBT.connect(standardUser).burn(9)).to.be.revertedWith(
          "Insufficient authority",
        )
      })

      it("Admin user can", async () => {
        await expect(hhSBT.connect(admin1).burn(13)).to.not.be.reverted
      })

      it("Tokens is burnt", async () => {
        expect(await hhSBT.balanceOf(admin1Addr)).to.equal(0)
      })

      it("Super user can", async () => {
        await expect(hhSBT.connect(superUser).burn(11)).to.not.be.reverted
      })

      it("Tokens is transferred", async () => {
        expect(await hhSBT.balanceOf(superUserAddr)).to.equal(0)
      })

      it("Super user cannot burn others", async () => {
        await expect(
          hhSBT.connect(superUser).burn(9),
        ).to.be.revertedWithCustomError(hhSBT, "ERC721InsufficientApproval")
      })
    })
  })

  context("Upgrades", function () {
    describe("Upgrading the Implementation contract", function () {
      let sbtUpgradeAddress: AddressLike
      let sbtAddressBefore: AddressLike
      let sbtImplementationBefore: AddressLike
      let sbtAddressAfter: AddressLike
      let sbtImplementationAfter: AddressLike

      before(async function () {
        sbtUpgradeAddress = await hhSBTUpgrade.getAddress()
      })

      it("Log addresses", async () => {
        sbtAddressBefore = await hhSBT.getAddress()
        console.log("          -> SBT address: ", sbtAddressBefore)
        sbtImplementationBefore =
          await upgrades.erc1967.getImplementationAddress(
            sbtAddressBefore as string,
          )
        console.log(
          "          -> Implementation address: ",
          sbtImplementationBefore,
        )
      })

      it("Check version", async () => {
        expect(await hhSBT.version()).to.equal("1.0")
      })

      it("Random cannot upgrade the implementation contract", async () => {
        await expect(
          hhSBT.connect(random).upgradeToAndCall(sbtUpgradeAddress, "0x"),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Owner cannot upgrade the implementation contract", async () => {
        await expect(
          hhSBT.connect(owner).upgradeToAndCall(sbtUpgradeAddress, "0x"),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Admin cannot upgrade the implementation contract", async () => {
        await expect(
          hhSBT.connect(admin1).upgradeToAndCall(sbtUpgradeAddress, "0x"),
        ).to.be.revertedWithCustomError(
          hhSBT,
          "AccessControlUnauthorizedAccount",
        )
      })

      it("Upgrade admin cannot upgrade the implementation contract without prior approval", async () => {
        await expect(
          hhSBT.connect(upgradeAdmin).upgradeToAndCall(sbtUpgradeAddress, "0x"),
        ).to.be.revertedWith("Upgrade not approved")
      })

      it("Owner can approve upgrade", async () => {
        await expect(hhSBT.connect(owner).setUpgradeApproved(true)).to.not.be
          .reverted
      })

      it("Upgrade admin can upgrade the implementation", async () => {
        await expect(
          hhSBT.connect(upgradeAdmin).upgradeToAndCall(sbtUpgradeAddress, "0x"),
        ).to.not.be.reverted
      })

      it("Log addresses", async () => {
        sbtAddressAfter = await hhSBT.getAddress()
        console.log("          -> SBT address: ", sbtAddressAfter)
        sbtImplementationAfter =
          await upgrades.erc1967.getImplementationAddress(
            sbtAddressAfter as string,
          )
        console.log(
          "          -> Implementation address: ",
          sbtImplementationAfter,
        )
      })

      it("Check addresses", async () => {
        expect(sbtAddressBefore).to.equal(sbtAddressAfter)
        expect(sbtImplementationBefore).to.not.equal(sbtImplementationAfter)
        expect(sbtImplementationAfter).to.equal(sbtUpgradeAddress)
      })

      it("Check version is upgraded", async () => {
        expect(await hhSBT.version()).to.equal("2.0")
      })
    })
  })
})
