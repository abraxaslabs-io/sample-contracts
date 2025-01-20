// SPDX-License-Identifier: MIT

/**
 * @title MockERC20.sol. Mock ERC20 for us in testing
 *
 * @author abraxas https://abraxaslabs.io
 */

pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  uint256 public constant MINT_AMOUNT = 1e25; // 1 million per recipient

  constructor(
    string memory name_,
    string memory symbol_,
    address[] memory recipients_
  ) ERC20(name_, symbol_) {
    for (uint256 i = 0; i < recipients_.length; i++) {
      _mint(recipients_[i], MINT_AMOUNT);
    }
  }
}
