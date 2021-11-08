pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {

// Defining the variables
    uint public totalPool;
    uint public rewardsPerEth;
    address manager;
    
    // mapping eth deposited based on a user address
    mapping(address=>uint) public userDeposits;
    
    // mapping a penalty based on a user address
    mapping(address=>uint) public userRewardTally;
    
    // Events
    event PoolDeposits(address user, uint value);
    event RewardsDistributed(uint value);
    event TotalPool(uint value);
    event WithdrawFunds(
      address user,
      uint amount,
      bool rewards
    );

    event RewardsTally(
      address user,
      uint value
    );


    constructor() {
        manager = msg.sender;
        rewardsPerEth = 0;
        totalPool = 0;
    }
    
    /* 
      function that will take deposits to put into the pool;and how much of a rewards tally a person has.
      The tally is calculated at when a person makes a deposit so it is a way to keep a record of what rewards have already
      been distrubuted and what a user is entitled to if they join the pool late in the game
      */
    function userDeposit() public payable{
        // Increase the size of the amount in the pool and set the rewards tally
        require(msg.value>0, "You must deposit some eth.");
        userDeposits[msg.sender] = userDeposits[msg.sender] + msg.value;
        userRewardTally[msg.sender] = userRewardTally[msg.sender] + rewardsPerEth * msg.value;
        totalPool = totalPool + msg.value;
        emit TotalPool(totalPool);
        emit PoolDeposits(msg.sender, msg.value);
        emit RewardsTally(msg.sender, userRewardTally[msg.sender]);
    }
    
    modifier restricted() {
        require(msg.sender==manager);
        _;
    }
    
    // Function to distrubute reward ethereum
    function distributeRewards () public restricted payable{
        require(totalPool>0, "Can't distribute rewards to a pool without any deposits");
        require(msg.value>0, "Can't distribute 0 rewards");
        // Calculates a ration of the rewards per eth and then stores it as a whole number
        rewardsPerEth = rewardsPerEth + ((msg.value * 10**18) / totalPool);
        emit RewardsDistributed(msg.value);
    }
    
    // Function to calculate the rewards based on the rewards per eth 
    
    function compute_reward(address _address) public view returns(uint) {
        return (userDeposits[_address] * rewardsPerEth - userRewardTally[_address]) / 10**18;
    }
    
    // Withdraw function that will allow a user to withdraw their deposit
    function withdrawDeposit() public {
        uint withdraw = userDeposits[msg.sender];
        require(withdraw>0, "Address doesn't have any deposits to withdraw");
        userRewardTally[msg.sender] = userRewardTally[msg.sender] - rewardsPerEth * withdraw;
        totalPool = totalPool - withdraw;
        payable(msg.sender).transfer(withdraw);
        emit WithdrawFunds(msg.sender, withdraw, false);
    }

    // Withdraw function that will allow a user to get all of their Rewards
    function withdrawRewards() public {
        uint reward = compute_reward(msg.sender);
        require(reward>0, "You don't have any rewards to withdraw.");
        userRewardTally[msg.sender] = userDeposits[msg.sender] * rewardsPerEth;
        payable(msg.sender).transfer(reward);
        emit WithdrawFunds(msg.sender, reward, true);
    }
}
