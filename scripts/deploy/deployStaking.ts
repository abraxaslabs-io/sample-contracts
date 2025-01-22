// npx hardhat run --network sepolia scripts/deploy/deployStaking.ts

import { ethers } from "hardhat"
import hre from "hardhat"
import { writeFileSync, unlinkSync } from "fs"

// CONFIGURATION STARTS //
//
const token = "0x88974155fDD1d3264dfEE9Ea870ED32cbf2778DE"
const minStake = BigInt(1e20).toString() // 100
const maxStake = BigInt(1e21).toString() // 1000
const durations = [30]
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

  const staking = await ethers.getContractFactory("Staking")
  const hhStaking = await staking.deploy(token, minStake, maxStake, durations)
  console.log("Waiting for deployment to complete, please wait...")
  const deployedAddress = await hhStaking.getAddress()
  await hhStaking.waitForDeployment()
  await wait(120)

  console.log("Contract deployed!")
  console.log("Staking: ", deployedAddress)

  console.log("Verifying contract, please wait...")
  const tempFile = `./tempConstructorArgs${deployedAddress}.json`
  try {
    writeFileSync(
      tempFile,
      JSON.stringify([token, minStake, maxStake, durations]),
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
