// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityLearningCenterGovernance {

    address public admin;
    uint256 public proposalCount;

    // Struct for storing details of each proposal
    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 endTime;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event Voted(uint256 proposalId, address voter, bool inFavor);
    event ProposalExecuted(uint256 proposalId, bool passed);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!proposals[_proposalId].hasVoted[msg.sender], "You have already voted on this proposal");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp <= proposals[_proposalId].endTime, "Proposal voting has ended");
        _;
    }

    modifier proposalEnded(uint256 _proposalId) {
        require(block.timestamp > proposals[_proposalId].endTime, "Proposal voting is still ongoing");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createProposal(string memory _description, uint256 _duration) external onlyAdmin {
        proposalCount++;
        uint256 endTime = block.timestamp + _duration;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = _description;
        newProposal.endTime = endTime;

        emit ProposalCreated(proposalCount, _description, endTime);
    }

    function vote(uint256 _proposalId, bool _inFavor) external proposalExists(_proposalId) notVoted(_proposalId) proposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (_inFavor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _inFavor);
    }

    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) proposalEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        bool passed = proposal.votesFor > proposal.votesAgainst;
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, passed);
    }

    function getProposalVotes(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 votesFor, uint256 votesAgainst) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.votesFor, proposal.votesAgainst);
    }

    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposals = new uint256[](proposalCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= proposalCount; i++) {
            if (block.timestamp <= proposals[i].endTime) {
                activeProposals[index] = i;
                index++;
            }
        }

        return activeProposals;
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (string memory description, uint256 votesFor, uint256 votesAgainst, uint256 endTime) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.endTime);
    }
}
