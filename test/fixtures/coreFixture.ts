import { ethers, upgrades } from "hardhat"
import { Signer, AddressLike } from "ethers"
import { MockERC20 } from "../../typechain/contracts/mock/token/MockERC20"
import { Staking } from "../../typechain/contracts/finance/Staking"
import { SBTUpgradeable } from "../../typechain/contracts/token/SBTUpgradeable/SBTUpgradeable"

export type { MockERC20, Staking, SBTUpgradeable }

let owner: Signer
let addr1: Signer
let addr2: Signer
let addr3: Signer
let addr4: Signer
let addr5: Signer
let addr6: Signer
let addr7: Signer
let addr8: Signer
let addrs: Signer[]
let ownerAddress: AddressLike
let address1: AddressLike
let address2: AddressLike
let address3: AddressLike
let address4: AddressLike
let address5: AddressLike
let address6: AddressLike
let address7: AddressLike
let address8: AddressLike
let hhMockERC20: MockERC20
let hhMockERC20Address: AddressLike
let hhStaking: Staking
let hhStakingAddress: AddressLike
let hhSBT: SBTUpgradeable

const minStake = ethers.parseEther("1000")
const maxStake = ethers.parseEther("1000000")
const durations = [30, 60, 90]

export async function deployFixture() {
  ;[owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, ...addrs] =
    await ethers.getSigners()

  address1 = await addr1.getAddress()
  address2 = await addr2.getAddress()
  address3 = await addr3.getAddress()
  address4 = await addr4.getAddress()
  address5 = await addr5.getAddress()
  address6 = await addr6.getAddress()
  address7 = await addr7.getAddress()
  address8 = await addr8.getAddress()
  ownerAddress = await owner.getAddress()

  const mockERC20 = await ethers.getContractFactory("MockERC20")
  hhMockERC20 = (await mockERC20.deploy("Mock ERC20", "MOCK20", [
    address1,
    address2,
    address3,
    address4,
  ])) as MockERC20

  hhMockERC20Address = await hhMockERC20.getAddress()

  const staking = await ethers.getContractFactory("Staking")
  hhStaking = (await staking.deploy(
    await hhMockERC20.getAddress(),
    minStake,
    maxStake,
    durations,
  )) as Staking

  hhStakingAddress = await hhStaking.getAddress()

  const sbt = await ethers.getContractFactory("SBTUpgradeable")
  hhSBT = (await upgrades.deployProxy(sbt, [
    "Test SBT",
    "TSTSBT",
    "https://something.com",
    address1,
    [address2, address3],
  ])) as any as SBTUpgradeable

  return {
    owner,
    addr1,
    addr2,
    addr3,
    addr4,
    addr5,
    addr6,
    addr7,
    addr8,
    addrs,
    ownerAddress,
    address1,
    address2,
    address3,
    address4,
    address5,
    address6,
    address7,
    address8,
    hhMockERC20,
    hhStaking,
    hhMockERC20Address,
    hhStakingAddress,
    minStake,
    maxStake,
    durations,
    hhSBT,
  }
}
