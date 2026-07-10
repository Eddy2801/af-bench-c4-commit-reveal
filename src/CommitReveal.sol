// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CommitReveal - commit-reveal voting with no funds at risk
contract CommitReveal {
    uint256 public immutable commitDeadline;
    uint256 public immutable revealDeadline;
    uint256 public immutable numOptions;

    mapping(address => bytes32) public commits;
    mapping(address => bool) public revealed;
    mapping(uint256 => uint256) public voteCounts;

    event Committed(address indexed voter);
    event Revealed(address indexed voter, uint256 option);

    constructor(uint256 _commitDuration, uint256 _revealDuration, uint256 _numOptions) {
        require(_commitDuration > 0 && _revealDuration > 0, "zero duration");
        require(_numOptions > 1, "need options");
        commitDeadline = block.timestamp + _commitDuration;
        revealDeadline = block.timestamp + _commitDuration + _revealDuration;
        numOptions = _numOptions;
    }

    function commit(bytes32 hash) external {
        require(block.timestamp < commitDeadline, "commit phase ended");
        require(commits[msg.sender] == bytes32(0), "already committed");
        commits[msg.sender] = hash;
        emit Committed(msg.sender);
    }

    function reveal(uint256 option, bytes32 salt) external {
        require(block.timestamp >= commitDeadline, "commit phase active");
        require(block.timestamp < revealDeadline, "reveal phase ended");
        require(!revealed[msg.sender], "already revealed");
        require(option < numOptions, "invalid option");

        bytes32 expected = keccak256(abi.encodePacked(msg.sender, option, salt));
        require(commits[msg.sender] == expected, "hash mismatch");

        revealed[msg.sender] = true;
        voteCounts[option]++;
        emit Revealed(msg.sender, option);
    }

    function getWinner() external view returns (uint256 winningOption, uint256 winningVotes) {
        require(block.timestamp >= revealDeadline, "voting not finished");
        for (uint256 i = 0; i < numOptions; i++) {
            if (voteCounts[i] > winningVotes) {
                winningVotes = voteCounts[i];
                winningOption = i;
            }
        }
    }
}
