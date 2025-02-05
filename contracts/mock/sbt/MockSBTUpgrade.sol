// SPDX-License-Identifier: MIT

/**
 * @title MockSBTUpgrade.sol. Mock upgrade for us in testing
 *
 * @notice This sample contract is provided as-is, and had not been audited. Use at your own risk.
 *
 * @author abraxas https://abraxaslabs.io
 */

pragma solidity 0.8.28;

import {SBTUpgradeable} from "../../token/SBTUpgradeable/SBTUpgradeable.sol";

contract MockSBTUpgrade is SBTUpgradeable {
  /**
   * @dev version Returns the version of the contract.
   * @return version_ A string representing the version.
   */
  function version() external pure override returns (string memory version_) {
    version_ = "2.0";
    return (version_);
  }
}
