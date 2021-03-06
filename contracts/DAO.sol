// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DAO {
	/**
     * 1. Collects investors money (ether)
     * 2. Keep track of investor contributions with shares
     * 3. Allow investors to transfer shares
     * 4. Allow investment proposals to be created and voted
     * 5. Execute successful investment proposal (i.e. send money)
    */

    struct Proposal {
        uint id;
        string name;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool executed;
    }

    mapping(address => bool) public investors;
    mapping(address => uint) public shares;
    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => bool)) public votes;
    uint public totalShares;
    uint public availableFunds;
    uint public contributionEnd;
    uint public nextProposalId;
    uint public voteTime;
    // A quorum is the minimum number of votes that a distributed transaction has to obtain in order to be allowed to perform an operation in a distributed system.
    uint public quorum;
    address public chairman;
    
    constructor(
        uint contributionTime,
        uint _voteTime,
        uint _quorum
    ) {
        require(_quorum > 0 && _quorum < 100, 'Quorum must be between 1 and 99');
        contributionEnd = block.timestamp + contributionTime;
        _voteTime = _voteTime;
        quorum = _quorum;
        chairman = msg.sender;
    }
    
    function contribute() payable external {
        require(contributionEnd > block.timestamp, "cannot contribute after contribution is end");
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }
    
    /**
     * 1. Allow investors to redeem shares
     */
    function redeemShare(uint amount) external payable {
        require(shares[msg.sender] >= amount, "not enought shares");
        require(availableFunds >= amount, "not enought availableFunds");
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transferShare(uint amount, address to) external {
        require(shares[msg.sender] >= amount, "not enought shares");
        shares[msg.sender] -= amount;
        shares[to] += amount;
        investors[to] = true;
    }

    function createProposal(
        string _name,
        uint _amount,
        address payable _recipient,
        uint _end
    ) external onlyInvestors {
        require(availableFunds >= _amount, "not enought available funds");
        proposals[nextProposalId] = Proposal(
            nextProposalId,
            _name,
            _amount,
            _recipient,
            0,
            block.timestamp + voteTime,
            false
        );
        availableFunds -= _amount;
        nextProposalId++;
    }

    function vote(uint proposalId) external onlyInvestors {
        // Storage pointer to selected proposal
        Proposal storage proposal = proposals[proposalId];
        
        require(votes[msg.sender][proposalId] == false, "already voted");
        require(proposal.end > block.timestamp, "you can only vote until proposal end");

        votes[msg.sender][proposalId] = true;
        proposal.votes += shares[msg.sender];
    }

    function executeProposal(uint proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.end < block.timestamp, "you can only execute proposal after it's end");
        require(proposal.executed == false, "proposal already executed");
        require((proposal.votes / totalShares) * 100 >= quorum, "not enough votes");
        _transferEther(proposal.recipient, proposal.amount);
    }

    function withdrawEther(uint amount, address payable to) external onlyChairman() {
        _transferEther(to, amount);
    }

    function _tranferEther(address to, uint amount) internal {
        require(availableFunds >= amount, "not enought available funds");
        availableFunds -= amount;
        payable(to).transfer(amount);
    }

    modifier onlyInvestors() {
        require(investors[msg.sender] == true, "only investors can execute");
        _;
    }

    modifier onlyChairman() {
        require(chairman == msg.sender, "only chairman can execute");
        _;
    }

    fallback() payable external {
        availableFunds += msg.value;
    }
}
