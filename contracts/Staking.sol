// SPDX-License-Identifier: MIT
/**
 * @title Staking.sol.
 *
 * @notice Very simple staking contract.
 *         * Allows taking of a single ERC20, defined below as the stakedToken.
 *
 * @author abraxas https://abraxaslabs.io
 *
 *         version 0.1.0
 */

pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Staking {
  struct Stake {
    uint256 amount;
    uint256 expiry;
    bool withdrawn;
  }

  /// @dev stakedToken: The ERC20 token that this contract will allow to be staked. This parameter
  /// has been set as immutable. That means that once it is set in the constructor it cannot be altered.
  ///
  /// @dev State variables can be:
  /// - constant   These are set at design time and cannot be set in the constructor or when the contract is live.
  ///              Use these when you have a value that you know will never change, no matter where you use it (i.e.
  ///              it will be the same on all environments, testing, production etc). These do NOT occupy storage on
  ///              the chain and therefore do not incur a gas cost to read.
  /// - immutable  These must be set in the constructor and cannot change in-life. Use these where you want to experiment
  ///              with different values in the build process (for testing etc) or in different versions of the contract.
  ///              These do NOT occupy storage on the chain and therefore do not incur a gas cost to read.
  /// - mutable    These have neither the constant or immutable keyword, and ARE in storage on the chain. They can be altered
  ///              in-life IF you have coded a method to alter them. As they occupy storage they incur a cost to read.
  IERC20 public immutable stakedToken;

  /// @dev minStakeAmount: The minimum amount that can be staked, with amounts below this causing a revert. This parameter
  /// has been set as immutable. That means that once it is set in the constructor it cannot be altered.

  uint256 public immutable minStakeAmount;

  /// @dev maxStakeAmount: The maximum amount that can be staked, with amounts above this causing a revert. This parameter
  /// has been set as immutable. That means that once it is set in the constructor it cannot be altered.
  uint256 public immutable maxStakeAmount;

  /// @dev allowedDurations: Allowed staking durations in days. This assumes that this staking contract will allow more than one
  /// duration (e.g. 30, 60, 90 days). If you only have a single allowed duration it would use less gas to store the single
  /// allowed duration as an immutable variable.
  mapping(uint256 durationInDays => bool allowed) public allowedDurations;

  mapping(address owner => Stake[] stakes) public ownerStakes;

  event Staked(
    address indexed owner,
    uint256 index,
    uint256 amount,
    uint256 duration,
    uint256 expiry
  );

  /**
   * @notice constructor: The constructor of a contract runs once when the contract is instantiated. It is used to setup
   * initial default values.
   *
   * @param token_ The address of the ERC20 token that this contract will stake.
   * @param minStake_ The minimum stake amount. Staked amounts less than this amount will not be accepted.
   * @param maxStake_ The maximum stake amount. Staked amount greater than this amount will not be accepted.
   * @param durations_ An array of the allowed staking durations in days, for example
   * [30, 60, 90] to allow taking for 30, 60 or 90 days.
   */
  constructor(
    address token_,
    uint256 minStake_,
    uint256 maxStake_,
    uint256[] memory durations_
  ) {
    // Set the token that this contract will stake:
    stakedToken = IERC20(token_);

    // Set the min stake amount to that passed on the constructor:
    minStakeAmount = minStake_;

    // Set the max stake amount to that passed on the constructor:
    maxStakeAmount = maxStake_;

    // Iterate through the passed durations and mark then as allowed:
    for (uint256 i = 0; i < durations_.length; i++) {
      allowedDurations[durations_[i]] = true;
    }
  }

  /**
   * @notice stake: A user stakes for the provided duration.
   *
   * @param amount_ The amount being staked.
   * @param duration_ The duration of the stake.
   */
  function stake(uint256 amount_, uint256 duration_) external {
    _preTransferValidation(duration_);

    uint256 transferredAmount = _transferStake(amount_);

    _postTransferValidation(transferredAmount);

    _recordStake(transferredAmount, duration_);
  }

  /**
   * @notice _preTransferValidation: Pre-transfer validation of  the arguments passed in
   * on the stake call.
   *
   * @param duration_ The duration of the stake.
   */
  function _preTransferValidation(uint256 duration_) internal view {
    if (!allowedDurations[duration_]) {
      revert("Invalid duration in days");
    }
  }

  /**
   * @notice _transferStake: Transfer the stake amount from the owner, validating that the
   * balance of this contract has increased by the required amount post-transfer. This is relevant
   * for token contract that implement transfer taxation, or any functionality that will reduce the amount
   * delivered below the amount requested. We check this to make sure we record the actual amount received,
   * not just assume that the amount requested has been staked.
   *
   * @param amount_ The amount being staked.
   */
  function _transferStake(
    uint256 amount_
  ) internal returns (uint256 transferredAmount_) {
    // Transfer the token across, recording how much actually arrives:
    uint256 preBalance = stakedToken.balanceOf(address(this));
    stakedToken.transferFrom(msg.sender, address(this), amount_);
    uint256 postBalance = stakedToken.balanceOf(address(this));
    return (postBalance - preBalance);
  }

  /**
   * @notice _postTransferValidation: Post-transfer validation of  the arguments passed in
   * on the stake call.
   *
   * @param amount_ The amount being staked.
   */
  function _postTransferValidation(uint256 amount_) internal view {
    if (amount_ < minStakeAmount) {
      revert("Stake amount too low");
    }
    if (amount_ > maxStakeAmount) {
      revert("Stake amount too high");
    }
  }

  /**
   * @notice _recordStake: Add the stake record to storage.
   *
   * @param amount_ The amount being staked.
   */
  function _recordStake(uint256 amount_, uint256 duration_) internal {
    uint256 expiry = block.timestamp + (duration_ * 1 days);

    uint256 stakeIndex = ownerStakes[msg.sender].length;

    // Record the stake:
    Stake memory newStake = Stake(amount_, expiry, false);
    ownerStakes[msg.sender].push(newStake);

    emit Staked(msg.sender, stakeIndex, amount_, duration_, expiry);
  }
}
