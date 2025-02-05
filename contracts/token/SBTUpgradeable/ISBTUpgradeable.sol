// SPDX-License-Identifier: MIT
/**
 * @title ISBTUpgradeable.sol.
 *
 * @notice Interface for a SBT (soul bound token) that is upgradeable
 *
 * @notice This sample contract is provided as-is, and had not been audited. Use at your own risk.
 *
 * @notice Functional Summary
 *
 *         * Upgradeable
 *         * Enumerable (added for convenience, remove this if gas cost is a key consideration)
 *         * Implements access control with four roles:
 *           - Owner. Can:
 *             - Assign roles
 *             - Approve the contract for upgrade
 *           - Admin. Can:
 *             - Mint
 *             - Burn (including non-owned tokens)
 *             - Revoke (transfer non-owned tokens)
 *             - Update the URI, including if it's a single URI for all or token specific
 *           - Super User. Can:
 *             - Transfer tokens they own
 *           - Upgrade Admin. Can:
 *             - Upgrade the contract (if prior approval from Owner)
 *         * Standard Users cannot transfer or burn their own tokens
 *         * All operations can be run in batch
 *
 * @notice Approach
 *
 *         This contract is a simple non-transferable ERC-721 using the UUPS upgradeable mechanism. It is
 *         designed to be centrally managed by an admin user or users to mint, burn and transfer tokens
 *         as required.
 *
 *         As this contract is upgradeable it can be altered to add additional functionality. Refer to the
 *         openzeppelin documentation for guidance on upgrading: https://docs.openzeppelin.com/contracts/4.x/api/proxy
 *
 *
 * @author abraxas https://abraxaslabs.io
 *
 *         version 0.1.0
 */

/// @dev Set the compiler version. It is best practice to fix to a version, if possible.
pragma solidity 0.8.28;

interface ISBTUpgradeable {
  struct SBTStorage {
    address owner;
    string baseURI;
    uint256 nextId;
    bool individualURI;
    bool upgradeApproved;
  }

  struct SBTTransfer {
    uint256 tokenId;
    address from;
    address to;
  }

  event BatchBurnComplete(uint256 burnedCount);
  event IndividualURIUpdated(bool oldIndividualURI, bool newIndividualURI);
  event BatchMintComplete(uint256 mintedCount);
  event BatchTransferComplete(uint256 transferredCount);
  event NonFunctionalOwnerUpdated(address oldOwner, address newOwner);
  event UpgradeApprovedUpdated(bool oldApproved, bool newApproved);
  event URIUpdated(string oldURI, string newURI);

  /**
   * @dev version Returns the version of the contract.
   *
   * @return version_ A string representing the version.
   */
  function version() external pure returns (string memory version_);

  /**
   * @dev nextTokenId Returns the next tokenId
   *
   * @return id_ The next tokenId
   */
  function nextTokenId() external view returns (uint256 id_);

  /**
   * @dev individualURI: Returns the value of individualURI, which controls
   * behaviour of tokenURI()
   *
   * @return individualURI_ The value of individualURI.
   */
  function individualURI() external view returns (bool individualURI_);

  /**
   * @dev upgradeApproved: Returns the value of upgradeApproved, which controls
   * whether the UPGRADE_ADMIN can upgrade the contract.
   *
   * @return upgradeApproved_ The value of upgradeApproved.
   */
  function upgradeApproved() external view returns (bool upgradeApproved_);

  /**
   * @dev baseURI: Returns the value of _baseURI,
   *
   * @return baseURI_ The value of _baseURI.
   */
  function baseURI() external view returns (string memory baseURI_);

  /**
   * @dev setURI: Allows the owner to set the URI for the token metadata.
   *
   * @param newURI_ The new URI for the token metadata.
   */
  function setURI(string memory newURI_) external;

  /**
   * @dev setIndividualURI: Allows the operator to specify if URIs should be specific for each
   * NFT or a single URI applies to all items. This is useful for a period of time when all
   * NFTs share the same metadata / image.
   *
   * @param individualURI_ A boolean for whether NFTs have individual images.
   */
  function setIndividualURI(bool individualURI_) external;

  /**
   * @dev setUpgradeApproved: Allows the owner (holder of the DEFAULT_ADMIN_ROLE)
   * to set the upgradeApproved flag. This allows a holder of the UPGRADE_ROLE
   * to upgrade the contract.
   *
   * @param upgradeApproved_ A boolean for whether an upgrade is approved.
   */
  function setUpgradeApproved(bool upgradeApproved_) external;

  /**
   * @dev batchMint: Mint tokens to a batch of addresses
   *
   * @param recipients_ An array of addresses.
   */
  function batchMint(address[] memory recipients_) external;

  /**
   * @dev batchBurn: Burn a batch of tokens
   *
   * @param ids_ An array of token Ids.
   */
  function batchBurn(uint256[] memory ids_) external;

  /**
   * @dev batchTransfer: Transfer a batch of tokens
   *
   * @param transfers_ An array of transfer objects
   */
  function batchTransfer(SBTTransfer[] calldata transfers_) external;

  /**
   * @dev burn: Burns `tokenId`. See {ERC721-_burn}.
   *
   * @param tokenId_ The token Id
   * Requirements:
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId_) external;
}
