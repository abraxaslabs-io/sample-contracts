// SPDX-License-Identifier: MIT
/**
 * @title SBTUpgradeable.sol.
 *
 * @notice A simple SBT (soul bound token) that is upgradeable
 *
 * @notice This sample contract is provided as-is, and had not been audited. Use at your own risk.
 *
 * @notice Functional Summary
 *
 *         * Upgradeable
 *         *  Enumerable (added for convenience, remove this if gas cost is a key consideration)
 *         * Implements access control with two roles:
 *           - Admin. This address can upgrade the contract
 *           - Operator. This address can mint, burn, transfer and update the URI
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

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC721EnumerableUpgradeable, ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ISBTUpgradeable} from "./ISBTUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @dev the `contract` statement must define what else this contract implements, in this case it's own interface and ReentrancyGuard.
contract SBTUpgradeable is
  AccessControlUpgradeable,
  ERC721EnumerableUpgradeable,
  ISBTUpgradeable,
  UUPSUpgradeable
{
  using Strings for uint256;

  bytes32 public constant OPERATOR_ROLE = keccak256("SBT_OPERATOR");

  bytes32 private constant storageLocation =
    0xa01c1ac3789f0242b5fc9c53b42f156686ebc36edc918201803f217ae7382200; // keccak256(abi.encode(uint256(keccak256("SBT")) - 1)) & ~bytes32(uint256(0xff));

  /**
   * @dev initialize: Set initial configuration.
   */
  function initialize(
    string calldata name_,
    string calldata symbol_,
    string memory baseURI_,
    address admin_,
    address[] memory operatorAddresses_
  ) public initializer {
    __UUPSUpgradeable_init();
    __AccessControl_init();
    __ERC721_init(name_, symbol_);

    _storage().baseURI = baseURI_;

    _grantRole(DEFAULT_ADMIN_ROLE, admin_);

    for (uint256 i = 0; i < operatorAddresses_.length; i++) {
      _grantRole(OPERATOR_ROLE, operatorAddresses_[i]);
    }

    // Start tokenIds at 1
    _storage().nextId = 1;
  }

  /**
   * @dev version Returns the version of the contract.
   * @return version_ A string representing the version.
   */
  function version() external pure returns (string memory version_) {
    version_ = "1.0";
    return (version_);
  }

  /**
   * @dev nextTokenId Returns the next tokenId
   * @return id_ The next tokenId
   */
  function nextTokenId() external view returns (uint256 id_) {
    return _storage().nextId;
  }

  /**
   * @dev individualURI: Returns the value of individualURI, which controls
   * behaviour of tokenURI()
   * @return individualURI_ The value of individualURI.
   */
  function individualURI() external view returns (bool individualURI_) {
    return _storage().individualURI;
  }

  /**
   * @dev baseURI: Returns the value of _baseURI,
   * @return baseURI_ The value of _baseURI.
   */
  function baseURI() external view returns (string memory baseURI_) {
    return _baseURI();
  }

  /**
   * @dev setURI: Allows the owner to set the URI for the token metadata.
   * @param newURI_ The new URI for the token metadata.
   */
  function setURI(string memory newURI_) external onlyRole(OPERATOR_ROLE) {
    string memory oldURI = _storage().baseURI;
    _storage().baseURI = newURI_;
    emit URIUpdated(oldURI, newURI_);
  }

  /**
   * @dev setIndividualURI: Allows the operator to specify if URIs should be specific for each
   * NFT or a single URI applies to all items. This is useful for a period of time when all
   * NFTs share the same metadata / image.
   * @param individualURI_ A boolean for whether NFTs have individual images.
   */
  function setIndividualURI(
    bool individualURI_
  ) external onlyRole(OPERATOR_ROLE) {
    bool oldIndividualURI = _storage().individualURI;
    _storage().individualURI = individualURI_;
    emit IndividualURIUpdated(oldIndividualURI, individualURI_);
  }

  function batchMint(address[] memory recipients_) external {
    uint256 tokenId = _storage().nextId;

    for (uint256 i = 0; i < recipients_.length; i++) {
      _mint(recipients_[i], tokenId);
      tokenId++;
    }

    _storage().nextId = tokenId;

    emit BatchMintComplete(recipients_.length);
  }

  function batchBurn(uint256[] memory ids_) external {
    for (uint256 i = 0; i < ids_.length; i++) {
      _burn(ids_[i]);
    }

    emit BatchBurnComplete(ids_.length);
  }

  function batchTransfer(SBTTransfer[] calldata transfers_) external {
    for (uint256 i = 0; i < transfers_.length; i++) {
      _transfer(transfers_[i].from, transfers_[i].to, transfers_[i].tokenId);
    }

    emit BatchTransferComplete(transfers_.length);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory tokenURI_) {
    _requireOwned(tokenId);

    tokenURI_ = _baseURI();

    if (_storage().individualURI) {
      tokenURI_ = string.concat(tokenURI_, "/", tokenId.toString());
    }

    return (tokenURI_);
  }

  /**
   * @dev Prevents setting approvals for operators as part of soulbound mechanism
   */
  function setApprovalForAll(
    address,
    bool
  ) public virtual override(ERC721Upgradeable, IERC721) {
    revert("SBT");
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _update(
    address to,
    uint256 tokenId,
    address auth
  ) internal override onlyRole(OPERATOR_ROLE) returns (address) {
    return super._update(to, tokenId, auth);
  }

  function _storage() private pure returns (SBTStorage storage $) {
    assembly {
      $.slot := storageLocation
    }
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view override returns (string memory) {
    return _storage().baseURI;
  }

  function _authorizeUpgrade(
    address
  ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
