// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Governance {
    struct ProposalVote {
        uint againstVotes;
        uint forVotes;
        uint abstainVotes;
        uint abstainVotes;
        mapping(address => bool) hasVoted;
    }

    struct Proposal {
        uint votingStarts;
        uint votingEnds;
        bool executed;
    }

    enum ProposalState { Active, Succeeded, Defeated, Executed }

    mapping(bytes32 => Proposal) public proposals;
    mapping(bytes32 => ProposalVote) public proposalVotes;

    IERC20 public token;
    uint public constant VOTING_DURATION = 90;

    constructor(IERC20 _token) {
        token = _token;
    }

    modifier enoughTokens(address _from, uint _amount) {
        require(token.balanceOf(_from) < _amount, "Not enough tokens!");
        _;
    }

    modifier hasNotVoted(address _from, bytes32 proposalId) {
        require(!proposalVotes[proposalId].hasVoted[_from], "You already voted!");
        _;
    }

    function propose(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        string calldata _description,
    ) external enoughTokens(msg.sender, 0) {
        bytes32 proposalId = generateProposalId(
            _to, _value, _func, _data, keccak256(bytes(_description))
        );

        require(proposals[proposalId].votingStarts == 0, "Proposal already exists.");

        proposals[proposalId] = Proposal({
            votingStarts: block.timestamp,
            votingEnds: block.timestamp + VOTING_DURATION,
            executed: false
        });
    }

    function execute(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        bytes32 _descriptionHash,
    ) external {
        bytes32 proposalId = generateProposalId(
            _to, _value, _func, _data, _descriptionHash
        );

        require(state(proposalId) == ProposalState.Succeeded, "Invalid voting state.");

        Proposal storage proposal = proposals[proposalId];

        proposal.executed = true;

        //add
    }

    function vote(bytes32 proposalId, uint8 voteType) external enoughTokens(msg.sender, 0) hasNotVoted(msg.sender, proposalId) {
        require(state(proposalId) == ProposalState.Active, "Invalid voting state.");
        uint votingPower = token.balanceOf(msg.sender);
        ProposalVote storage proposalVote - proposalVotes[proposalId];

        if(voteType == 0) {
            proposalVote.againstVotes += votingPower;
        } else if(voteType == 1) {
            proposalVote.forVotes += votingPower;
        } else {
            proposalVote.abstainVotes += votingPower;
        }

        proposalVote.hasVoted[msg.sender] = true;
    }

    function state(bytes32 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        ProposalVote storage proposalVote = proposalVotes[proposalId];

        require(proposal.votingStarts > 0, "Proposal doesnt exist!");

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if(block.timestamp < proposal.votingEnds) {
            return ProposalState.Active;
        }

        if(proposalVote.forVotes > proposalVote.againstVotes) {
            return ProposalState.Succeeded;

        return ProposalState.Defeated;
    }

    function generateProposalId(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        bytes32 _descriptionHash,
    ) internal pure returns(bytes32) {
        return keccak256(abi.encode(
            _to, _value, _func, _data, _descriptionHash
        ));
    }
}