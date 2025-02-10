// SPDX-License-Identifier: MIT
/**
 * @title SBTUpgradeable.sol.
 *
 * @notice A SBT (soul bound token) that is upgradeable
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

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {ERC721EnumerableUpgradeable, ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ISBTUpgradeable} from "./ISBTUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SBTUpgradeable is
  AccessControlEnumerableUpgradeable,
  ERC721EnumerableUpgradeable,
  ISBTUpgradeable,
  UUPSUpgradeable
{
  using Strings for uint256;

  /// @dev User roles to determine function specific access rights:
  bytes32 public constant ADMIN_ROLE = keccak256("SBT_ADMIN");
  bytes32 public constant UPGRADE_ROLE = keccak256("SBT_UPGRADE");
  bytes32 public constant SUPER_USER_ROLE = keccak256("SBT_SUPER_USER");

  /// @dev Storage location to avoid memory corruption on upgrade:
  bytes32 private constant storageLocation =
    0xa01c1ac3789f0242b5fc9c53b42f156686ebc36edc918201803f217ae7382200; // keccak256(abi.encode(uint256(keccak256("SBT")) - 1)) & ~bytes32(uint256(0xff));

  /**
   * @dev initialize: Set initial configuration.
   *
   * @param name_ The name of the token
   * @param symbol_ The symbol of the token
   * @param baseURI_ The base URI for metadata
   * @param individualURI_ If tokens have an individual URI (true) or not (false)
   * @param owner_ Address for the owner role
   * @param upgradeAdmin_ Address for the upgrade admin role
   * @param adminAddresses_ Array of addresses to set as admins
   * @param superUserAddresses_ Array of addresses to set as super users
   */
  function initialize(
    string calldata name_,
    string calldata symbol_,
    string memory baseURI_,
    bool individualURI_,
    address owner_,
    address upgradeAdmin_,
    address[] memory adminAddresses_,
    address[] memory superUserAddresses_
  ) public initializer {
    __UUPSUpgradeable_init();
    __AccessControl_init();
    __ERC721_init(name_, symbol_);

    SBTStorage storage $ = _storage();

    $.baseURI = baseURI_;

    _grantRole(DEFAULT_ADMIN_ROLE, owner_);
    $.owner = owner_;

    _grantRole(UPGRADE_ROLE, upgradeAdmin_);

    for (uint256 i = 0; i < adminAddresses_.length; i++) {
      _grantRole(ADMIN_ROLE, adminAddresses_[i]);
    }

    for (uint256 i = 0; i < superUserAddresses_.length; i++) {
      _grantRole(SUPER_USER_ROLE, superUserAddresses_[i]);
    }

    // Start tokenIds at 1
    $.nextId = 1;

    $.individualURI = individualURI_;
  }

  /**
   * @dev version Returns the version of the contract.
   *
   * @return version_ A string representing the version.
   */
  function version() external pure virtual returns (string memory version_) {
    version_ = "1.0";
    return (version_);
  }

  /**
   * @dev nextTokenId Returns the next tokenId
   *
   * @return id_ The next tokenId
   */
  function nextTokenId() external view returns (uint256 id_) {
    return _storage().nextId;
  }

  /**
   * @dev individualURI: Returns the value of individualURI, which controls
   * behaviour of tokenURI()
   *
   * @return individualURI_ The value of individualURI.
   */
  function individualURI() external view returns (bool individualURI_) {
    return _storage().individualURI;
  }

  /**
   * @dev upgradeApproved: Returns the value of upgradeApproved, which controls
   * whether the UPGRADE_ADMIN can upgrade the contract.
   *
   * @return upgradeApproved_ The value of upgradeApproved.
   */
  function upgradeApproved() external view returns (bool upgradeApproved_) {
    return _storage().upgradeApproved;
  }

  /**
   * @dev baseURI: Returns the value of _baseURI,
   *
   * @return baseURI_ The value of _baseURI.
   */
  function baseURI() external view returns (string memory baseURI_) {
    return _baseURI();
  }

  /**
   * @dev owner: A single owner storage variable is provided on this contract
   * to allow compatibility with off-chain platforms that assume a contract with
   * permissions will have an owner(). This can prove a problem for contracts using
   * access control that want to take actions on those platforms. It is controlled
   * by the DEFAULT_ADMIN_ROLE.
   *
   * ** It has no permissions on this contract **
   *
   * @return owner_ The value of the non functional owner.
   */
  function owner() public view virtual returns (address owner_) {
    return _storage().owner;
  }

  /**
   * @dev setNonFunctionalOwner: A single owner storage variable is provided on this contract
   * to allow compatibility with off-chain platforms that assume a contract with
   * permissions will have an owner(). This can prove a problem for contracts using
   * access control that want to take actions on those platforms. It is controlled
   * by the DEFAULT_ADMIN_ROLE.
   *
   * ** It has no permissions on this contract **
   *
   * @param newOwner_ The new address for the owner storage var.
   */
  function setNonFunctionalOwner(
    address newOwner_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    address oldOwner = _storage().owner;
    _storage().owner = newOwner_;
    emit NonFunctionalOwnerUpdated(oldOwner, newOwner_);
  }

  /**
   * @dev setURI: Allows the owner to set the URI for the token metadata.
   *
   * @param newURI_ The new URI for the token metadata.
   */
  function setURI(string memory newURI_) external onlyRole(ADMIN_ROLE) {
    string memory oldURI = _storage().baseURI;
    _storage().baseURI = newURI_;
    emit URIUpdated(oldURI, newURI_);
  }

  /**
   * @dev setIndividualURI: Allows the operator to specify if URIs should be specific for each
   * NFT or a single URI applies to all items. This is useful for a period of time when all
   * NFTs share the same metadata / image.
   *
   * @param individualURI_ A boolean for whether NFTs have individual images.
   */
  function setIndividualURI(bool individualURI_) external onlyRole(ADMIN_ROLE) {
    bool oldIndividualURI = _storage().individualURI;
    _storage().individualURI = individualURI_;
    emit IndividualURIUpdated(oldIndividualURI, individualURI_);
  }

  /**
   * @dev setUpgradeApproved: Allows the owner (holder of the DEFAULT_ADMIN_ROLE)
   * to set the upgradeApproved flag. This allows a holder of the UPGRADE_ROLE
   * to upgrade the contract.
   *
   * @param upgradeApproved_ A boolean for whether an upgrade is approved.
   */
  function setUpgradeApproved(
    bool upgradeApproved_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    bool oldUpgradeApproved = _storage().upgradeApproved;
    _storage().upgradeApproved = upgradeApproved_;
    emit UpgradeApprovedUpdated(oldUpgradeApproved, upgradeApproved_);
  }

  /**
   * @dev batchMint: Mint tokens to a batch of addresses
   *
   * @param recipients_ An array of addresses.
   */
  function batchMint(
    address[] memory recipients_
  ) external onlyRole(ADMIN_ROLE) {
    uint256 tokenId = _storage().nextId;

    for (uint256 i = 0; i < recipients_.length; i++) {
      _mint(recipients_[i], tokenId);
      tokenId++;
    }

    _storage().nextId = tokenId;

    emit BatchMintComplete(recipients_.length);
  }

  /**
   * @dev batchBurn: Burn a batch of tokens
   *
   * @param ids_ An array of token Ids.
   */
  function batchBurn(uint256[] memory ids_) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < ids_.length; i++) {
      _burn(ids_[i]);
    }

    emit BatchBurnComplete(ids_.length);
  }

  /**
   * @dev batchTransfer: Transfer a batch of tokens
   *
   * @param transfers_ An array of transfer objects
   */
  function batchTransfer(
    SBTTransfer[] calldata transfers_
  ) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < transfers_.length; i++) {
      _transfer(transfers_[i].from, transfers_[i].to, transfers_[i].tokenId);
    }

    emit BatchTransferComplete(transfers_.length);
  }

  /**
   * @dev tokenURI: Returns the URI for a token
   *
   * @param tokenId_ The token Id.
   * @return tokenURI_ The token URI.
   */
  function tokenURI(
    uint256 tokenId_
  ) public view override returns (string memory tokenURI_) {
    _requireOwned(tokenId_);

    tokenURI_ = _baseURI();

    if (_storage().individualURI) {
      tokenURI_ = string.concat(tokenURI_, "/", tokenId_.toString());
    }

    return (tokenURI_);
  }

  /**
   * @dev setApprovalForAll: Set approval, but only for authorised users.
   *
   * @param operator_ The operator
   * @param approved_ If the operator is approved
   */
  function setApprovalForAll(
    address operator_,
    bool approved_
  ) public override(ERC721Upgradeable, IERC721) {
    _checkTransferRoles();
    super.setApprovalForAll(operator_, approved_);
  }

  /**
   * @dev approve: Set approval for one token, but only for authorised users.
   *
   * @param to_ The operator
   * @param tokenId_ The token Id
   */
  function approve(
    address to_,
    uint256 tokenId_
  ) public override(ERC721Upgradeable, IERC721) {
    _checkTransferRoles();
    super.approve(to_, tokenId_);
  }

  /**
   * @dev burn: Burns `tokenId`. See {ERC721-_burn}.
   *
   * @param tokenId_ The token Id
   * Requirements:
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId_) external {
    // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
    // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
    _update(address(0), tokenId_, _msgSender());
  }

  /**
   * @dev supportsInterface: Returns if this contract supports an interface
   *
   * @param interfaceId The interface Id.
   * @param supported_ If the interface is supported.
   */
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
    returns (bool supported_)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev _update: Update token details. Override is provided here to restrict to only
   * authorised users
   *
   * @param to_ The address the token is moving to
   * @param tokenId_ The token Id being moved.
   * @param auth_ Whether auth is checked.
   */
  function _update(
    address to_,
    uint256 tokenId_,
    address auth_
  ) internal override returns (address) {
    // Updates can only be made by holders of either the ADMIN_ROLE or the SUPER_USER_ROLE
    // Only ADMIN_ROLE holders can mint, burn, or revoke (transfer SBTs held by other holders). The
    // SUPER_USER_ROLE is allowed access to the _update method, and therefore can transfer SBTs that
    // they hold themselves.
    _checkTransferRoles();
    return super._update(to_, tokenId_, auth_);
  }

  /**
   * @dev _storage: Return the storage slot
   *
   * @return $ The slot
   */
  function _storage() private pure returns (SBTStorage storage $) {
    assembly {
      $.slot := storageLocation
    }
  }

  /**
   * @dev _checkTransferRoles: Revert if the sender does not have the right role.
   */
  function _checkTransferRoles() internal view {
    if (
      !hasRole(ADMIN_ROLE, msg.sender) && !hasRole(SUPER_USER_ROLE, msg.sender)
    ) {
      revert("Insufficient authority");
    }
  }

  /**
   * @dev _baseURI: Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view override returns (string memory) {
    return _storage().baseURI;
  }

  /**
   * @dev _authorizeUpgrade: Control the circumstances of an upgrade.
   */
  function _authorizeUpgrade(address) internal override onlyRole(UPGRADE_ROLE) {
    if (!_storage().upgradeApproved) {
      revert("Upgrade not approved");
    }
    _storage().upgradeApproved = false;
  }
}
