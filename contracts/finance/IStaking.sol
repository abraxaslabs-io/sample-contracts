// SPDX-License-Identifier: MIT
/**
 * @title IStaking.sol.
 *
 * @notice Interface for Staking.sol.
 *
 * @notice This sample contract is provided as-is, and had not been audited. Use at your own risk.
 *
 * @author abraxas https://abraxaslabs.io
 *
 *         version 0.1.0
 */

pragma solidity 0.8.28;

interface IStaking {
  /// @dev A **struct** is a custom data type that allows you to define complex data structures by grouping related variables.
  /// It is useful for creating more meaningful and organized data models within smart contracts.
  ///
  /// @notice `Stake`: Struct to hold the stake information, being amount, expiry and if it has been withdrawn. An array of these
  /// `Stake` structs is mapped to owner addresses (see ownerStakes below).
  struct Stake {
    uint256 amount;
    uint64 durationInDays;
    uint64 stakedTimestamp;
    uint64 expiryTimestamp;
    uint64 withdrawnTimestamp;
  }
  ///
  /// @notice `StakesWithOwner`: Struct to hold the owner and an array of owned stakes, used in a view method "report".
  struct StakesWithOwner {
    address owner;
    Stake[] stakes;
  }
  ///
  /// @notice `UnstakeRequest`: A single unstake request, consisting of the owner and the index being unstaked.
  struct UnstakeRequest {
    address owner;
    uint64 index;
  }

  /// @dev An **event** is a message emitted outside of the blockchain, and can be read and parsed by providers. They are used to keep track of
  /// on-chain events, for both reporting and other off-chain activities (for example calculating staking yields).
  ///
  /// @notice `Staked` is the event emitted when a new stake is made. With this event, as with other aspects in this simple sample contract, we
  /// are *not* optimising for low gas usage, but rather for functionality and convenience. This is expressed here with us emitting both the
  /// staked timestamp (which will also be available on the transaction object), and the duration of the stake (which is a function of the
  /// staked and expiry timestamps). This provides a more data rich event where off-chain services do not need to collect additional data, at the
  /// cost of a higher amount of gas. On any L2 / L3 this would be entirely insignificant in terms of cost.
  /// withdrawnAt will always be 0, but it pads that last slot to a full bytes32 and means that the Stake and Unstake messages have the same format.
  event Staked(
    address indexed owner,
    uint96 index,
    uint256 amount,
    uint64 duration,
    uint64 stakedAt,
    uint64 expiresAt,
    uint64 withdrawnAt
  );

  /// @notice `Unstaked` is the event emitted when a stake is unstaked. With this event, as with the `stake` event above, we are not optimising for
  /// low gas but emitting details we could reasonable exclude if gas cost was a key concern (in which case we would emit only the address and index).
  event Unstaked(
    address indexed owner,
    uint96 index,
    uint256 amount,
    uint64 duration,
    uint64 stakedAt,
    uint64 expiresAt,
    uint64 withdrawnAt
  );

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
  ) external view returns (bool isAllowed_);

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
  ) external view returns (Stake[] memory stakesForOwner_);

  /**
   * @notice allStakeOwners: Returns all of owners that have staked amounts.
   *
   * @return allOwners_ An array of all owner addresses.
   */
  function allStakeOwners() external view returns (address[] memory allOwners_);

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
    returns (StakesWithOwner[] memory allStakes_);

  /**
   * @notice `stake`: A user stakes for the provided duration.
   *
   * @param amount_ The amount being staked.
   * @param duration_ The duration of the stake.
   */
  function stake(uint256 amount_, uint64 duration_) external;

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
  function unstake(UnstakeRequest[] calldata unstakeRequests_) external;
}
