// npx hardhat run --network sepolia scripts/deploy/deploySBT.ts
// npx hardhat run --network bartio scripts/deploy/deploySBT.ts

// npx hardhat verify --network bartio 0xeE54e80F31300eD4301a229CE92e2E405D44d402

import { ethers, upgrades } from "hardhat"
import hre from "hardhat"
import { writeFileSync, unlinkSync } from "fs"

// CONFIGURATION STARTS //
//
const name = "Test SBT"
const symbol = "TSTSBT"
const baseURI = "https://notaurl.com"
const individualURI = false
const owner = "0x8aa0952d10a5925d1a9D20879a9C91326F486FC7"
const upgradeAdmin = "0x8aa0952d10a5925d1a9D20879a9C91326F486FC7"
const admins = [
  "0x8aa0952d10a5925d1a9D20879a9C91326F486FC7",
  "0x781c0A00E0F98E75d0eaaaF3a01083e22a91ebc1",
]
const superUsers = ["0x4556c8a5C80A5CE2c1bA2A599d4315AC3F064270"]
//
// CONFIGURATION ENDS //

async function wait(seconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000))
}

async function main() {
  let deployer: any
  try {
    ;[deployer] = await ethers.getSigners()
  } catch (err) {
    console.log("Signer error")
    throw err
  }

  const network = await ethers.provider.getNetwork()
  console.log(
    `Deploy to network: ${network.name} (chain number: ${network.chainId})`,
  )
  console.log("Using:", deployer.address)

  const sbt = await ethers.getContractFactory("SBTUpgradeable")
  const hhSBT = await upgrades.deployProxy(sbt, [
    name,
    symbol,
    baseURI,
    individualURI,
    owner,
    upgradeAdmin,
    admins,
    superUsers,
  ])

  console.log("Waiting for deployment to complete, please wait...")
  const deployedAddress = await hhSBT.getAddress()
  await hhSBT.waitForDeployment()
  await wait(120)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    deployedAddress,
  )

  console.log("Contract deployed!")
  console.log("SBT: ", deployedAddress)
  console.log("Implementation: ", implementationAddress)

  console.log("Verifying contracts, please wait...")
  const tempFile = `./tempConstructorArgs${deployedAddress}.json`

  try {
    await hre.run("verify", {
      address: implementationAddress,
    })

    writeFileSync(
      tempFile,
      JSON.stringify([
        name,
        symbol,
        baseURI,
        individualURI,
        owner,
        upgradeAdmin,
        admins,
        superUsers,
      ]),
    )
    await hre.run("verify", {
      address: deployedAddress,
      constructorArgs: tempFile,
    })
    console.log("Contract verified successfully!")
  } catch (error: any) {
    console.error("Verification failed:", error.message)
  } finally {
    unlinkSync(tempFile)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
