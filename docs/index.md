# Solidity API

## IStaking

### Stake

`Stake`: Struct to hold the stake information, being amount, expiry and if it has been withdrawn. An array of these
`Stake` structs is mapped to owner addresses (see ownerStakes below).

_A **struct** is a custom data type that allows you to define complex data structures by grouping related variables.
It is useful for creating more meaningful and organized data models within smart contracts._

```solidity
struct Stake {
  uint256 amount;
  uint64 durationInDays;
  uint64 stakedTimestamp;
  uint64 expiryTimestamp;
  uint64 withdrawnTimestamp;
}
```

### StakesWithOwner

`StakesWithOwner`: Struct to hold the owner and an array of owned stakes, used in a view method "report".

```solidity
struct StakesWithOwner {
  address owner;
  struct IStaking.Stake[] stakes;
}
```

### UnstakeRequest

`UnstakeRequest`: A single unstake request, consisting of the owner and the index being unstaked.

```solidity
struct UnstakeRequest {
  address owner;
  uint64 index;
}
```

### Staked

```solidity
event Staked(address owner, uint96 index, uint256 amount, uint64 duration, uint64 stakedAt, uint64 expiresAt, uint64 withdrawnAt)
```

`Staked` is the event emitted when a new stake is made. With this event, as with other aspects in this simple sample contract, we
are *not* optimising for low gas usage, but rather for functionality and convenience. This is expressed here with us emitting both the
staked timestamp (which will also be available on the transaction object), and the duration of the stake (which is a function of the
staked and expiry timestamps). This provides a more data rich event where off-chain services do not need to collect additional data, at the
cost of a higher amount of gas. On any L2 / L3 this would be entirely insignificant in terms of cost.
withdrawnAt will always be 0, but it pads that last slot to a full bytes32 and means that the Stake and Unstake messages have the same format.

_An **event** is a message emitted outside of the blockchain, and can be read and parsed by providers. They are used to keep track of
on-chain events, for both reporting and other off-chain activities (for example calculating staking yields)._

### Unstaked

```solidity
event Unstaked(address owner, uint96 index, uint256 amount, uint64 duration, uint64 stakedAt, uint64 expiresAt, uint64 withdrawnAt)
```

`Unstaked` is the event emitted when a stake is unstaked. With this event, as with the `stake` event above, we are not optimising for
low gas but emitting details we could reasonable exclude if gas cost was a key concern (in which case we would emit only the address and index).

### allAllowedDurations

```solidity
function allAllowedDurations() external view returns (uint256[] allowedDurations_)
```

allAllowedDurations: Returns all allowed durations, purely as a convenience view function.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allowedDurations_ | uint256[] | All allowed durations. |

### isAllowedDuration

```solidity
function isAllowedDuration(uint256 duration_) external view returns (bool isAllowed_)
```

isAllowedDuration: Returns if a duration is allowed. We have made the storage item internal
(rather than public) and provided a view method as it allows us to explicitly declare this method in the contracts
interface. We believe this provides for a clearer, more explicit ABI and easier integration with other contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| duration_ | uint256 | The duration in days being queried. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| isAllowed_ | bool | If a duration is allowed. |

### allStakesForOwner

```solidity
function allStakesForOwner(address owner_) external view returns (struct IStaking.Stake[] stakesForOwner_)
```

allStakesForOwner: Returns all of the stakes for the queried owner. We have made the storage item internal
(rather than public) and provided a view method as it allows us to explicitly declare this method in the contracts
interface. We believe this provides for a clearer, more explicit ABI and easier integration with other contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | The owner we are querying. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| stakesForOwner_ | struct IStaking.Stake[] | An array of stakes for this owner. |

### allStakeOwners

```solidity
function allStakeOwners() external view returns (address[] allOwners_)
```

allStakeOwners: Returns all of owners that have staked amounts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allOwners_ | address[] | An array of all owner addresses. |

### allStakes

```solidity
function allStakes() external view returns (struct IStaking.StakesWithOwner[] allStakes_)
```

allStakes: Returns all stakes from storage. This could return a lot of data, and as
such may exceed the capacity of nodes to provide a response. It is therefore provided purely for
reporting and analysis purposes and is not core to the operation of this contract. Where a very large
volume of stakes are being recorded a more suitable approach is to monitor emitted events off-chain
and aggregate a view of owner / all stakes off-chain.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allStakes_ | struct IStaking.StakesWithOwner[] | An array of owners with their owned stakes. |

### stake

```solidity
function stake(uint256 amount_, uint64 duration_) external
```

`stake`: A user stakes for the provided duration.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount_ | uint256 | The amount being staked. |
| duration_ | uint64 | The duration of the stake. |

### unstake

```solidity
function unstake(struct IStaking.UnstakeRequest[] unstakeRequests_) external
```

`unstake`: Unstake amounts, withdrawing funds to the original owners, if the
staking period has expired.

This method is not restricted; any caller can make this call. This assumes that there are no
conceivable reason than an owner would not want to receive back their stake once the staking
period has expired. It allows for the possibility of "automated" withdrawals where the operator
of the staking programme processes withdrawals on behalf of users. For this reason the `unstake`
function takes batches of unstake requests.

If *any* of the unstake requests in the batch fail the entire function reverts.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| unstakeRequests_ | struct IStaking.UnstakeRequest[] | An array of unstake requests, these being the owner address and the index of the stake we want to withdraw. |

## Staking

_the `contract` statement must define what else this contract implements, in this case it's own interface and ReentrancyGuard._

### stakedToken

```solidity
contract IERC20 stakedToken
```

`stakedToken`: The ERC20 token that this contract will allow to be staked. This parameter
has been set as immutable. That means that once it is set in the constructor it cannot be altered.

_**state variables** can be:
- constant   These are set at design time and cannot be set in the constructor or when the contract is live.
             Use these when you have a value that you know will never change, no matter where you use it (i.e.
             it will be the same on all environments, testing, production etc). These do NOT occupy storage on
             the chain and therefore do not incur a gas cost to read.
- immutable  These must be set in the constructor and cannot change in-life. Use these where you want to experiment
             with different values in the build process (for testing etc) or in different versions of the contract.
             These do NOT occupy storage on the chain and therefore do not incur a gas cost to read.
- mutable    These have neither the constant or immutable keyword, and ARE in storage on the chain. They can be altered
             in-life IF you have coded a method to alter them. As they occupy storage they incur a cost to read._

### minStakeAmount

```solidity
uint256 minStakeAmount
```

`minStakeAmount`: The minimum amount that can be staked, with amounts below this causing a revert. This parameter
has been set as immutable. That means that once it is set in the constructor it cannot be altered.

### maxStakeAmount

```solidity
uint256 maxStakeAmount
```

`maxStakeAmount`: The maximum amount that can be staked, with amounts above this causing a revert. This parameter
has been set as immutable. That means that once it is set in the constructor it cannot be altered.

### ownerStakes

```solidity
mapping(address => struct IStaking.Stake[]) ownerStakes
```

`ownerStakes`: The stakes made by an owner held in an array of Stake structs.

### owners

```solidity
struct EnumerableSet.AddressSet owners
```

_**enumerable sets** from open zeppelin function as enumerable mappings. We use this here to enable us to return a report of all
stakes by owner._

### _allowedDurations

```solidity
struct EnumerableSet.UintSet _allowedDurations
```

`allowedDurations`: Allowed staking durations in days. This assumes that this staking contract will allow more than one
duration (e.g. 30, 60, 90 days). If you only have a single allowed duration it would use less gas to store the single
allowed duration as an immutable variable.

### constructor

```solidity
constructor(address token_, uint256 minStake_, uint256 maxStake_, uint256[] durations_) public
```

constructor: The constructor of a contract runs once when the contract is instantiated. It is used to setup
initial default values.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_ | address | The address of the ERC20 token that this contract will stake. |
| minStake_ | uint256 | The minimum stake amount. Staked amounts less than this amount will not be accepted. |
| maxStake_ | uint256 | The maximum stake amount. Staked amount greater than this amount will not be accepted. |
| durations_ | uint256[] | An array of the allowed staking durations in days, for example [30, 60, 90] to allow taking for 30, 60 or 90 days. |

### allAllowedDurations

```solidity
function allAllowedDurations() external view returns (uint256[] allowedDurations_)
```

allAllowedDurations: Returns all allowed durations, purely as a convenience view function.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allowedDurations_ | uint256[] | All allowed durations. |

### isAllowedDuration

```solidity
function isAllowedDuration(uint256 duration_) public view returns (bool isAllowed_)
```

isAllowedDuration: Returns if a duration is allowed. We have made the storage item internal
(rather than public) and provided a view method as it allows us to explicitly declare this method in the contracts
interface. We believe this provides for a clearer, more explicit ABI and easier integration with other contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| duration_ | uint256 | The duration in days being queried. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| isAllowed_ | bool | If a duration is allowed. |

### allStakesForOwner

```solidity
function allStakesForOwner(address owner_) external view returns (struct IStaking.Stake[] stakesForOwner_)
```

allStakesForOwner: Returns all of the stakes for the queried owner. We have made the storage item internal
(rather than public) and provided a view method as it allows us to explicitly declare this method in the contracts
interface. We believe this provides for a clearer, more explicit ABI and easier integration with other contracts.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | The owner we are querying. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| stakesForOwner_ | struct IStaking.Stake[] | An array of stakes for this owner. |

### allStakeOwners

```solidity
function allStakeOwners() external view returns (address[] allOwners_)
```

allStakeOwners: Returns all of owners that have staked amounts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allOwners_ | address[] | An array of all owner addresses. |

### allStakes

```solidity
function allStakes() external view returns (struct IStaking.StakesWithOwner[] allStakes_)
```

allStakes: Returns all stakes from storage. This could return a lot of data, and as
such may exceed the capacity of nodes to provide a response. It is therefore provided purely for
reporting and analysis purposes and is not core to the operation of this contract. Where a very large
volume of stakes are being recorded a more suitable approach is to monitor emitted events off-chain
and aggregate a view of owner / all stakes off-chain.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allStakes_ | struct IStaking.StakesWithOwner[] | An array of owners with their owned stakes. |

### stake

```solidity
function stake(uint256 amount_, uint64 duration_) external
```

`stake`: A user stakes for the provided duration. The user must have first approved this contract
on the stakedToken for an allowance equal to or greater than the amount being staked.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount_ | uint256 | The amount being staked. |
| duration_ | uint64 | The duration of the stake. |

### unstake

```solidity
function unstake(struct IStaking.UnstakeRequest[] unstakeRequests_) external
```

`unstake`: Unstake amounts, withdrawing funds to the original owners, if the
staking period has expired.

This method is not restricted; any caller can make this call. This assumes that there are no
conceivable reason than an owner would not want to receive back their stake once the staking
period has expired. It allows for the possibility of "automated" withdrawals where the operator
of the staking programme processes withdrawals on behalf of users. For this reason the `unstake`
function takes batches of unstake requests.

If *any* of the unstake requests in the batch fail the entire function reverts.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| unstakeRequests_ | struct IStaking.UnstakeRequest[] | An array of unstake requests, these being the owner address and the index of the stake we want to withdraw. |

### receive

```solidity
receive() external payable
```

### _preTransferValidation

```solidity
function _preTransferValidation(uint256 duration_) internal view
```

_preTransferValidation: Pre-transfer validation of  the arguments passed in
on the stake call.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| duration_ | uint256 | The duration of the stake. |

### _transferStake

```solidity
function _transferStake(address owner_, uint256 amount_) internal returns (uint256 transferredAmount_)
```

_transferStake: Transfer the stake amount from the owner, validating that the
balance of this contract has increased by the required amount post-transfer. This is relevant
for token contract that implement transfer taxation, or any functionality that will reduce the amount
delivered below the amount requested. We check this to make sure we record the actual amount received,
not just assume that the amount requested has been staked.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | The owner making the stake. |
| amount_ | uint256 | The amount being staked. |

### _postTransferValidation

```solidity
function _postTransferValidation(uint256 amount_) internal view
```

_postTransferValidation: Post-transfer validation of  the arguments passed in
on the stake call.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount_ | uint256 | The amount being staked. |

### _recordStake

```solidity
function _recordStake(address owner_, uint256 amount_, uint64 duration_) internal
```

_recordStake: Add the stake record to storage.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | The owner making the stake. |
| amount_ | uint256 | The amount being staked. |
| duration_ | uint64 | The duration of the stake. |

### _unstake

```solidity
function _unstake(address owner_, uint64 index_) internal
```

_unstake: Unstake the amount for an individual staking item.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | The owner of the stake. |
| index_ | uint64 | The index in the owners array of stakes to unstake. |

## MockERC20

### MINT_AMOUNT

```solidity
uint256 MINT_AMOUNT
```

### constructor

```solidity
constructor(string name_, string symbol_, address[] recipients_) public
```

### mint

```solidity
function mint(uint256 amount_) external
```

