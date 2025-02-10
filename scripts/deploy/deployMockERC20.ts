// npx hardhat run --network sepolia scripts/deploy/deployMockERC20.ts
// npx hardhat run --network berachain scripts/deploy/deployMockERC20.ts

import { ethers } from "hardhat"
import hre from "hardhat"
import readline from "readline"
import { writeFileSync, unlinkSync } from "fs"

export const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
})

export function promptUser(query: any, defaultValue: any) {
  return new Promise((resolve) => {
    rl.question(`${query} (default ${defaultValue}): `, (answer) => {
      resolve(answer || defaultValue)
    })
  })
}

async function wait(seconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000))
}

async function main() {
  const name = (await promptUser("Token Name", "Test ERC20")) as string
  const symbol = (await promptUser("Token Symbol", "TSTERC20")) as string
  const recipientsInput = (await promptUser(
    "Mint to (comma-separated list)",
    "",
  )) as string
  const owners = recipientsInput
    .split(",")
    .map((addr) => addr.trim())
    .filter((addr) => ethers.isAddress(addr))

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

  const mockERC20 = await ethers.getContractFactory("MockERC20")
  const hhNewERC20 = await mockERC20.deploy(name, symbol, owners)
  console.log("Waiting for deployment to complete, please wait...")
  const deployedAddress = await hhNewERC20.getAddress()
  await hhNewERC20.waitForDeployment()
  await wait(70)

  console.log("Contract deployed!")
  console.log("MockERC20: ", deployedAddress)

  console.log("Verifying contract, please wait...")
  const tempFile = `./tempConstructorArgs${deployedAddress}.json`
  try {
    writeFileSync(tempFile, JSON.stringify([name, symbol, owners]))
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
