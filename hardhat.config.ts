import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "@nomicfoundation/hardhat-verify"
import "solidity-docgen"
import "dotenv/config"
import "@openzeppelin/hardhat-upgrades"

// Private keys are needed to interact with chains, most commonly for deploying
// contracts using deployment scripts. These private keys should NOT be used for
// anything other than deployments, they should not own anything or have any other
// privileges, and should be stored in env vars not on repositories.
const TESTNET_PRIVATE_KEY = process.env.TESTNET_PRIVATE_KEY
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY
const ALCHEMY_KEY = process.env.ALCHEMY_KEY

// API keys for verifying contracts on chains.
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""

// Chain definitions.
const mainnet = {
  chainId: 1,
  rpc: `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`,
  scanner: "https://etherscan.io",
}
const world = {
  chainId: 480,
  rpc: `https://worldchain-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`,
  scanner: "https://worldscan.org/",
}
const sepolia = {
  chainId: 11155111,
  rpc: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_KEY}`,
  scanner: "https://sepolia.etherscan.io/",
}
const worldSepolia = {
  chainId: 4801,
  rpc: `https://worldchain-sepolia.g.alchemy.com/v2/${ALCHEMY_KEY}`,
  scanner: "https://sepolia.worldscan.org/",
}
const bartio = {
  chainId: 80084,
  rpc: `https://berachain-bartio.g.alchemy.com/v2/${ALCHEMY_KEY}`,
  scanner: "https://bartio.beratrail.io/",
  scanAPI: "https://api.routescan.io/v2/network/testnet/evm/80084/etherscan",
}

const config: HardhatUserConfig = {
  // Type chain generates types from contracts for use with ts.
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },
  // Here you specify solidity defaults, the most common being the
  // compiler version and whether optimisation is enabled. Optimisation on
  // with 200 runs is a common default.
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },

  // Etherscan details for use with contract verification.
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      sepolia: ETHERSCAN_API_KEY,
      worldSepolia: ETHERSCAN_API_KEY,
      world: ETHERSCAN_API_KEY,
      bartio: "berachain_bartio", // apiKey is not required, just set a placeholder
    },
    customChains: [
      {
        network: "world",
        chainId: world.chainId,
        urls: {
          apiURL: world.rpc,
          browserURL: world.scanner,
        },
      },
      {
        network: "worldSepolia",
        chainId: worldSepolia.chainId,
        urls: {
          apiURL: worldSepolia.rpc,
          browserURL: worldSepolia.scanner,
        },
      },
      {
        network: "bartio",
        chainId: bartio.chainId,
        urls: {
          apiURL: bartio.scanAPI,
          browserURL: bartio.scanner,
        },
      },
    ],
  },

  // The networks we will use with this hardhat project.
  networks: {
    hardhat: {
      //
    },
    ...(MAINNET_PRIVATE_KEY && {
      mainnet: {
        url: mainnet.rpc,
        chainId: mainnet.chainId,
        accounts: [`0x${MAINNET_PRIVATE_KEY}`],
      },
      world: {
        url: world.rpc,
        chainId: world.chainId,
        accounts: [`0x${MAINNET_PRIVATE_KEY}`],
      },
    }),
    ...(TESTNET_PRIVATE_KEY && {
      sepolia: {
        url: sepolia.rpc,
        chainId: sepolia.chainId,
        accounts: [`0x${TESTNET_PRIVATE_KEY}`],
      },
      worldSepolia: {
        url: worldSepolia.rpc,
        chainId: worldSepolia.chainId,
        accounts: [`0x${TESTNET_PRIVATE_KEY}`],
      },
      bartio: {
        url: bartio.rpc,
        chainId: bartio.chainId,
        accounts: [`0x${TESTNET_PRIVATE_KEY}`],
      },
    }),
  },

  // Gas reported runs with unit tests and produces an estimate of gas usage for
  // deployments and method calls.
  gasReporter: {
    enabled: true,
  },
}

export default config
