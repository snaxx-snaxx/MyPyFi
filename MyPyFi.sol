// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc-3525/contracts/ERC3525.sol";

contract AgentCore is ERC3525, Ownable {
    using Strings for uint256;

    enum AgentType { Admin, Rehypo, Strategy, SlotBot }
    enum SlotCategory { TVL, Strategy, Rehypo }

    struct AgentInfo {
        uint256 agentId;
        AgentType agentType;
        address controller;
        uint256 slotId;
        bool isActive;
    }

    struct TradingAgentToken {
        uint256 tokenId;
        string label;
        uint256 profit;
    }

    // === Storage ===
    uint256 private _nextTokenId = 1;
    uint256 public agentCount;

    mapping(address => AgentInfo) public agents;
    mapping(uint256 => TradingAgentToken) public tokens;

    // === Events ===
    event AgentRegistered(uint256 indexed agentId, AgentType agentType, address controller, uint256 slotId);
    event BuySignal(uint256 indexed tokenId);
    event SellSignal(uint256 indexed tokenId);
    event ReEntrySignal(uint256 indexed tokenId);
    event ReturnSignal(uint256 indexed tokenId);
    event SessionLogged(uint256 indexed tokenId, string data, uint256 timestamp);
    event StrategyTuned(uint256 indexed tokenId, uint256 paramId, int256 adjustment);
    event LLMTask(uint256 indexed tokenId, string task);
    event LLMOutput(uint256 indexed tokenId, string output);

    // === Constructor ===
    constructor(address initialOwner) ERC3525("AgentCore", "AGENT", 18) Ownable(initialOwner) {}

    // === Modifiers ===
    modifier onlyAgent(uint256 tokenId) {
        AgentInfo memory agent = agents[msg.sender];
        require(agent.isActive && agent.slotId != 0, "Unauthorized");
        require(tokens[tokenId].tokenId != 0, "Invalid token");
        _;
    }

    // === Agent Ops ===
    function registerAgent(AgentType agentType, address controller, uint256 slotId) external onlyOwner {
        require(!agents[controller].isActive, "Already registered");
        agents[controller] = AgentInfo(agentCount, agentType, controller, slotId, true);
        emit AgentRegistered(agentCount, agentType, controller, slotId);
        agentCount++;
    }

    function mintAgentToken(string memory label, uint256 slotId, uint256 value) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(msg.sender, tokenId, slotId, value);
        tokens[tokenId] = TradingAgentToken(tokenId, label, 0);
        return tokenId;
    }

    // === Signal Ops ===
    function sendBuy(uint256 tokenId) external onlyAgent(tokenId) {
        emit BuySignal(tokenId);
    }

    function sendSell(uint256 tokenId) external onlyAgent(tokenId) {
        emit SellSignal(tokenId);
    }

    function sendReEntry(uint256 tokenId) external onlyAgent(tokenId) {
        emit ReEntrySignal(tokenId);
    }

    function returnToZone(uint256 tokenId) external onlyAgent(tokenId) {
        emit ReturnSignal(tokenId);
    }

    function logSession(uint256 tokenId, string calldata data) external onlyAgent(tokenId) {
        emit SessionLogged(tokenId, data, block.timestamp);
    }

    function tune(uint256 tokenId, uint256 paramId, int256 adj) external onlyAgent(tokenId) {
        emit StrategyTuned(tokenId, paramId, adj);
    }

    function callLLM(uint256 tokenId, string calldata task) external onlyAgent(tokenId) {
        emit LLMTask(tokenId, task);
    }

    function reviewLLM(uint256 tokenId, string calldata output) external onlyAgent(tokenId) {
        emit LLMOutput(tokenId, output);
    }
}
