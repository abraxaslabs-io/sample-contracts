// SPDX-License-Identifier: MIT
/**
 * @title ISBT.sol.
 *
 * @notice Interface for a simple SBT (soul bound token) that is upgradeable
 *
 * @notice This sample contract is provided as-is, and had not been audited. Use at your own risk.
 *
 * @notice Functional Summary
 *
 *         * Upgradeable
 *         *  Enumerable (added for convenience, remove this if gas cost is a key consideration)
 *         * Implements access control with two roles:
 *           - Owner. This address can upgrade the contract
 *           - Admin. This address can mint, burn, transfer and update the URI
 *         * Users cannot transfer or burn their own tokens
 *         * Admin user can mint new tokens, burn existing tokens, transfer existing tokens
 *         * All operations can be run in batch
 *
 * @notice Approach
 *
 *         This contract is a simple non-transferable ERC-721 using the UUPS upgradeable mechanism. It is
 *         designed to be centrally managed by an admin user or users to mint, burn and transfer tokens
 *         as required.
 *
 *         As this contract is upgradeable it can be altered to add additional functionality. Refer to the
 *         openzepplin documentation for guidance on upgrading: https://docs.openzeppelin.com/contracts/4.x/api/proxy
 *
 *
 * @author abraxas https://abraxaslabs.io
 *
 *         version 0.1.0
 */

/// @dev Set the compiler version. It is best practice to fix to a version, if possible.
pragma solidity 0.8.28;

interface ISBT {
  struct SBTStorage {
    string baseURI;
    uint256 nextId;
  }

  struct SBTTransfer {
    uint256 tokenId;
    address from;
    address to;
  }

  event BatchMintComplete(uint256 mintedCount);

  event BatchBurnComplete(uint256 burnedCount);

  event BatchTransferComplete(uint256 transferredCount);

  event URIUpdated(string oldURI, string newURI);
}
