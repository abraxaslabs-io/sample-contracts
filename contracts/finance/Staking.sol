// SPDX-License-Identifier: MIT
/**
 * @title Staking.sol.
 *
 * @notice Very simple staking contract.
 *
 * @notice Functional Summary
 *
 *         * No privileged access (now ownable or access control).
 *         * Allows taking of a single ERC20, defined below as the stakedToken, set in the constructor.
 *         * Allows only a pre-determined range of durations in days, set in the constructor.
 *         * Implements a minimum and maximum stake amount, set in the constructor.
 *         * Stakers can make multiple separate stakes, each is tracked individually.
 *         * Existing stakes cannot be added to.
 *         * When the staked period has expired any caller can unstake; funds are returned to the address that made the stake.
 *         * Stakes can be unstaked in batch (more than one stake unstaked in a transaction).
 *         * View methods for allStakeOwners, allStakesForOwner and allStakes.
 *
 * @notice Approach
 *
 *         This contract is designed to be used with no or minimal off-chain architecture, i.e. no requirement to watch and
 *         aggregate contract events. The view methods allow "reporting" and can be used directly in UIs (for example to
 *         display all the stakes an owner has made, and provide the indexes needed to unstake them). To achieve this we have
 *         made design choices that do not optimise for gas (for example storing an enumerable map of all owners). Rather the
 *         contract stores all information necessary for ease of use, allowing for swift implementation in a simple UI.
 *
 *         If using this sample as the basis for a gas optimised implementation you would remove the owner list from storage and
 *         rely instead on aggregating events in the UI. You would also remove detail from the Events emitted which duplicate
 *         information on the txn receipt itself and/or aren't strictly required (but are provided here for ease of use). You
 *         would also consider removing the reentrancy guard as the unstake method follows the check -> effects -> interaction
 *         pattern.
 *
 *
 * @author abraxas https://abraxaslabs.io
 *
 *         version 0.1.0
 */

/// @dev Set the compiler version. It is best practice to fix to a version, if possible.
pragma solidity 0.8.28;

/// @dev The interface for this contract contains struct and event definitions and method definitions for all external functions.
/// It can be imported by other contracts to make objects of this contract's type and easily make use of this contracts external
// methods.
import {IStaking} from "./IStaking.sol";
/// @dev We import `IERC20` to type the token that this contract can hold.
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/// @dev `EnumerableSet` provides a useful data type, see the comment at the `using` declaration below.
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
/// @dev We can use a `ReentrancyGuard` to protect against reentrancy attacks. See the `unstake` method for more details.
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @dev the `contract` statement must define what else this contract implements, in this case it's own interface and ReentrancyGuard.
contract Staking is IStaking, ReentrancyGuard {
  ///
  /// @dev We are using OpenZeppelins **EnumerableSet* to track all addresses that have staked in this contract. As detailed above,
  /// this isn't the most gas efficient approach, as it adds both a SLOAD and (for the first time an address stakes) a STORE to
  /// each staking operation. But it does allow the contract to return a 'report' of all staking. This approach (and other features)
  /// allow this contract to be used 'standalone' without specific reliance on aggregating emitted events to know the status of all
  /// stakes. If you are targetting a low gas cost you would take a different approach, and not store this information on-chain.
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @dev **state variables** can be:
  /// - constant   These are set at design time and cannot be set in the constructor or when the contract is live.
  ///              Use these when you have a value that you know will never change, no matter where you use it (i.e.
  ///              it will be the same on all environments, testing, production etc). These do NOT occupy storage on
  ///              the chain and therefore do not incur a gas cost to read.
  /// - immutable  These must be set in the constructor and cannot change in-life. Use these where you want to experiment
  ///              with different values in the build process (for testing etc) or in different versions of the contract.
  ///              These do NOT occupy storage on the chain and therefore do not incur a gas cost to read.
  /// - mutable    These have neither the constant or immutable keyword, and ARE in storage on the chain. They can be altered
  ///              in-life IF you have coded a method to alter them. As they occupy storage they incur a cost to read.
  ///
  /// @notice `stakedToken`: The ERC20 token that this contract will allow to be staked. This parameter
  /// has been set as immutable. That means that once it is set in the constructor it cannot be altered.
  IERC20 public immutable stakedToken;

  /// @notice `minStakeAmount`: The minimum amount that can be staked, with amounts below this causing a revert. This parameter
  /// has been set as immutable. That means that once it is set in the constructor it cannot be altered.
  uint256 public immutable minStakeAmount;

  /// @notice `maxStakeAmount`: The maximum amount that can be staked, with amounts above this causing a revert. This parameter
  /// has been set as immutable. That means that once it is set in the constructor it cannot be altered.
  uint256 public immutable maxStakeAmount;

  /// @dev A **mapping** is a data structure that acts as a key-value store, similar to a hash table or dictionary in other programming
  /// languages. It is used to efficiently store and retrieve data using keys, providing the mapped data when provided with the
  /// appropriate key.

  /// @notice `allowedDurations`: Allowed staking durations in days. This assumes that this staking contract will allow more than one
  /// duration (e.g. 30, 60, 90 days). If you only have a single allowed duration it would use less gas to store the single
  /// allowed duration as an immutable variable.
  mapping(uint256 durationInDays => bool allowed) internal allowedDurations;

  /// @dev An **array**, signified by [], is a data structure that stores multiple values of the same type in a single variable. Arrays can be
  /// fixed-size or dynamic, and they are useful for organizing and managing collections of data. The example below is a dynamic array in
  /// storage, it can be any length and is added to using the push command. Arrays can be in storage (on-chain) or memory (memory of the txn).

  /// @notice `ownerStakes`: The stakes made by an owner held in an array of Stake structs.
  mapping(address owner => Stake[] stakes) internal ownerStakes;

  /// @dev **enumerable sets** from open zeppelin function as enumerable mappings. We use this here to enable us to return a report of all
  /// stakes by owner.
  EnumerableSet.AddressSet internal owners;

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
   * @notice isAllowedDuration: Returns if a duration is allowed. We have made the storage item internal
   * (rather than public) and provided a view method as it allows us to explicitly declare this method in the contracts
   * interface. We believe this provides for a clearer, more explicit ABI and easier integration with other contract.
   *
   * @param duration_ The duration in days being queried.
   * @return isAllowed_ If a duration is allowed.
   */
  function isAllowedDuration(
    uint256 duration_
  ) external view returns (bool isAllowed_) {
    return allowedDurations[duration_];
  }

  /**
   * @notice allStakesForOwner: Returns all of the stakes for the queried owner. We have made the storage item internal
   * (rather than public) and provided a view method as it allows us to explicitly declare this method in the contracts
   * interface. We believe this provides for a clearer, more explicit ABI and easier integration with other contract.
   *
   * @param owner_ The owner we are querying.
   * @return stakesForOwner_ An array of stakes for this owner.
   */
  function allStakesForOwner(
    address owner_
  ) external view returns (Stake[] memory stakesForOwner_) {
    return ownerStakes[owner_];
  }

  /**
   * @notice allStakeOwners: Returns all of owners that have staked amounts.
   *
   * @return allOwners_ An array of all owner addresses.
   */
  function allStakeOwners()
    external
    view
    returns (address[] memory allOwners_)
  {
    return owners.values();
  }

  /**
   * @notice allStakes: Returns all stakes from storage. This could return a lot of data, and as
   * such may exceed the capacity of nodes to provide a response. It is therefore provided purely for
   * reporting and analysis purposes and is not core to the operation of this contract. Where a very large
   * volume of stakes are being recorded a more suitable approach is to monitor emitted events off-chain
   * and aggregate a view of owner / all stakes off-chain.
   *
   * @return allStakes_ An array of owners with their owned stakes.
   */
  function allStakes()
    external
    view
    returns (StakesWithOwner[] memory allStakes_)
  {
    uint256 ownerCount = owners.length();

    allStakes_ = new StakesWithOwner[](ownerCount);

    for (uint256 i = 0; i < ownerCount; i++) {
      address owner = owners.at(i);
      Stake[] storage stakes = ownerStakes[owner];

      Stake[] memory stakesCopy = new Stake[](stakes.length);
      for (uint256 j = 0; j < stakes.length; j++) {
        stakesCopy[j] = stakes[j];
      }

      allStakes_[i] = StakesWithOwner(owner, stakesCopy);
    }

    return allStakes_;
  }

  /**
   * @notice `stake`: A user stakes for the provided duration. The user must have first approved this contract
   * on the stakedToken for an allowance equal to or greater than the amount being staked.
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
   * @notice `unstake`: Unstake amounts, withdrawing funds to the original owners, if the
   * staking period has expired.
   *
   * This method is not restricted; any caller can make this call. This assumes that there are no
   * conceivable reason than an owner would not want to receive back their stake once the staking
   * period has expired. It allows for the possibility of "automated" withdrawals where the operator
   * of the staking programme processes withdrawals on behalf of users. For this reason the `unstake`
   * function takes batches of unstake requests.
   *
   * If *any* of the unstake requests in the batch fail the entire function reverts.
   *
   * @param unstakeRequests_ An array of unstake requests, these being the owner address and the index
   * of the stake we want to withdraw.
   */
  function unstake(UnstakeRequest[] calldata unstakeRequests_) external {
    // Iterate through the unstake requests and process them:
    for (uint256 i = 0; i < unstakeRequests_.length; i++) {
      _unstake(unstakeRequests_[i].owner, unstakeRequests_[i].index);
    }
  }

  receive() external payable {
    revert("No unexpected native token");
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
    // Add the address that is staking to the enumerable set if required:
    if (!owners.contains(msg.sender)) {
      owners.add(msg.sender);
    }

    // Set the staked at timestamp, which is the current block time:
    uint256 stakedAt = block.timestamp;

    // Set the staking expiry timestamp, which is the block time plus duration in days:
    uint256 expiresAt = stakedAt + (duration_ * 1 days);

    // We hold dates in uint80 to pack three together in one 256 bit slot. There is no reasonable way
    // that any of these dates can exceed a uint80 max value. Even if they did, the function would then
    // revert with an out of range error. But we can handle this remote possibility more gracefully:
    if (stakedAt > type(uint80).max || expiresAt > type(uint80).max) {
      revert("Invalid dates");
    }

    // Record the index we will add this stake too, which is the current length of the
    // stake array in `ownerStakes` for this owner:
    uint256 stakeIndex = ownerStakes[msg.sender].length;

    // Record the stake:
    Stake memory newStake = Stake(
      amount_,
      uint80(stakedAt),
      uint80(expiresAt),
      uint80(0)
    );
    ownerStakes[msg.sender].push(newStake);

    // Emit the details of this stake:
    emit Staked(
      msg.sender,
      stakeIndex,
      amount_,
      stakedAt,
      duration_,
      expiresAt
    );
  }

  /**
   * @notice _unstake: Unstake the amount for an individual staking item.
   *
   * @param owner_ The owner of the stake.
   * @param index_ The index in the owners array of stakes to unstake.
   */
  function _unstake(address owner_, uint256 index_) internal nonReentrant {
    /// @dev We are making use of the OpenZeppelin reentrancy guard on this function. If we wished to
    /// avoid the gas cost of this we could instead implement a strict check -> effects -> interaction.
    /// We should, in best practice, use this pattern in *all* cases, even when we are using a guard.
    /// Use of the correct pattern should be mandatory, with use of the guard being optional.
    ///
    /// Calling another contract, which includes transferring tokens or transferring native token
    /// to an address (which itself may be a contract) are potentially re-entrant actions. This means we
    /// pass control of execution to someone else's code, and cannot guarantee that code will not re-enter
    /// this processing loop before the operations here have completed.
    ///
    /// For this reason we need to follow the check -> effects -> interaction pattern, where we check that
    /// the operation can occur, then process *local* effects, and finally interact with other contract (i.e.
    /// perform the transfer / call etc.)
    ///
    /// This method serves as an example of this. First we check that the stake has not already been
    /// unstaked and that staking time has expired. Otherwise we cannot unstake.
    ///
    /// We then mark the stake as having been withdrawn. We must do this *before* the interaction with another
    /// contract. By doing so, we ensure that if this function is re-entered it will revert on the initial check
    /// (the staked item having been marked as withdrawn). If we did the interaction first, before marking the
    /// stake item as withdrawn, an attacker could loop the method many times and drain all funds.
    ///
    /// Finally we interact, in this case by sending ERC20s.

    /// @dev **checks**:
    // Check this hasn't already been unstaked.
    if (ownerStakes[owner_][index_].withdrawnTimestamp != 0) {
      revert("Already unstaked");
    }

    // Check the staking period has expired:
    if (ownerStakes[owner_][index_].expiryTimestamp > block.timestamp) {
      revert("Staking time has not yet expired");
    }

    /// @dev **effects**:
    // Mark the record as withdrawn:
    ownerStakes[owner_][index_].withdrawnTimestamp = uint80(block.timestamp);

    /// @dev **interactions**:
    // Transfer the staked amount to the owner:
    stakedToken.transfer(owner_, ownerStakes[owner_][index_].amount);

    // Emit the details of this unstake:
    emit Unstaked(
      msg.sender,
      index_,
      ownerStakes[owner_][index_].amount,
      ownerStakes[owner_][index_].stakedTimestamp,
      ownerStakes[owner_][index_].expiryTimestamp,
      block.timestamp
    );
  }
}
