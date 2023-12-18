// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CreatorInvestmentPlatform {
    // Struct for a single creator's project
    struct Project {
        string description;
        address payable creator;
        uint goalAmount;
        uint currentBalance;
        uint deadline;
        bool exists;
    }

    // State variables
    address public platformOwner;
    uint public projectCount;

    // Mapping from project ID to Project struct
    mapping(uint => Project) public projects;

    // Mapping from project ID to investments (investor address to amount)
    mapping(uint => mapping(address => uint)) public investments;

    // Events to track on-chain activities
    event ProjectCreated(uint projectId, address creator);
    event InvestmentReceived(uint projectId, address investor, uint amount);
    event FundsDisbursed(uint projectId, uint amount);

    // Contract initialization
    constructor() {
        platformOwner = msg.sender;  // Assign the contract deployer as the platform owner
        projectCount = 0;
    }

    // Function to create a new project
    function createProject(string memory _description, uint _goalAmount, uint _durationInDays) public {
        projectCount++;  // New project ID
        Project memory newProject = Project({
            description: _description,
            creator: payable(msg.sender),
            goalAmount: _goalAmount,
            currentBalance: 0,
            deadline: block.timestamp + (_durationInDays * 1 days),
            exists: true
        });
        projects[projectCount] = newProject;

        emit ProjectCreated(projectCount, msg.sender);
    }

    // Function to invest in a project
    function investInProject(uint _projectId) public payable {
        Project storage project = projects[_projectId];
        require(project.exists, "Project does not exist");
        require(block.timestamp < project.deadline, "Project funding deadline passed");
        require(msg.value + project.currentBalance <= project.goalAmount, "Investment exceeds funding goal");

        project.currentBalance += msg.value;
        investments[_projectId][msg.sender] += msg.value;

        emit InvestmentReceived(_projectId, msg.sender, msg.value);
    }

    // Function to disburse funds once the goal is met
    function disburseFunds(uint _projectId) public {
        Project storage project = projects[_projectId];
        require(project.exists, "Project does not exist");
        require(project.currentBalance >= project.goalAmount, "Funding goal not met");
        require(block.timestamp >= project.deadline, "Project deadline not reached");
        require(msg.sender == project.creator, "Only the project creator can disburse funds");

        uint amountToDisburse = project.currentBalance;
        project.currentBalance = 0;  // Avoid re-entrancy attacks

        project.creator.transfer(amountToDisburse);  // Transfer funds to creator

        emit FundsDisbursed(_projectId, amountToDisburse);
    }

    // Additional functions like refunding investors, handling revenue sharing, and more would be added here.
    // Also, real-world projects would require more advanced security measures, error handling, and regulatory compliance.
}
