// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LibDiamond.sol";

contract Staking {
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => StakeInfo) public stakes;
    IERC20 public rewardToken;
    uint256 public rewardRate = 100; // Reward tokens per day per ETH staked (adjust as needed)

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    function initialize(address _rewardToken) external {
        LibDiamond.enforceIsContractOwner();
        rewardToken = IERC20(_rewardToken);
    }

    function stake() external payable {
        require(msg.value > 0, "Cannot stake 0");

        // Update existing stake if any
        if (stakes[msg.sender].amount > 0) {
            _claimRewards();
        }

        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].timestamp = block.timestamp;

        emit Staked(msg.sender, msg.value);
    }

    function withdraw() external {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");

        _claimRewards();

        uint256 amount = userStake.amount;
        userStake.amount = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external {
        _claimRewards();
    }

    function _claimRewards() internal {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");

        uint256 timeStaked = block.timestamp - userStake.timestamp;
        uint256 rewards = (userStake.amount * rewardRate * timeStaked) /
            (1 days * 1 ether);

        if (rewards > 0) {
            userStake.timestamp = block.timestamp;
            require(
                rewardToken.transfer(msg.sender, rewards),
                "Reward transfer failed"
            );
            emit RewardsClaimed(msg.sender, rewards);
        }
    }

    function getStakeInfo(
        address _staker
    ) external view returns (uint256 amount, uint256 timestamp) {
        StakeInfo memory userStake = stakes[_staker];
        return (userStake.amount, userStake.timestamp);
    }

    function getPendingRewards(
        address _staker
    ) external view returns (uint256) {
        StakeInfo memory userStake = stakes[_staker];
        if (userStake.amount == 0) return 0;

        uint256 timeStaked = block.timestamp - userStake.timestamp;
        return
            (userStake.amount * rewardRate * timeStaked) / (1 days * 1 ether);
    }
}
