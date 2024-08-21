// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudentProfileSystem {
    struct Student {
        string name;
        string rollNo;
        string branch;
        string studentId;
        uint256 reputation;
        uint256 credits;
        uint256[] sharedResources;
    }

    struct Resource {
        string title;
        string description;
        address creator;
        uint256 accessCount;
    }

    mapping(address => Student) public students;
    mapping(string => address) public studentIds;  // Mapping to track unique student IDs
    mapping(uint256 => Resource) public resources;
    uint256 public resourceCount;
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyRegisteredStudent() {
        require(bytes(students[msg.sender].studentId).length > 0, "Student not registered");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Helper function to convert an address to a hexadecimal string
    function toHexString(address _addr) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory data = abi.encodePacked(_addr);
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // Function to generate student ID using year, branch, roll number, and student address
    function generateStudentId(string memory _year, string memory _branch, string memory _rollNo, address _studentAddress) internal pure returns (string memory) {
        return string(abi.encodePacked("dc", _year, _branch, _rollNo, toHexString(_studentAddress)));
    }

    // Register a new student
    function registerStudent(string memory _name, string memory _year, string memory _branch, string memory _rollNo) public {
        require(bytes(students[msg.sender].studentId).length == 0, "Student already registered");

        // Generate a student ID using the student's address to ensure uniqueness
        string memory newStudentId = generateStudentId(_year, _branch, _rollNo, msg.sender);
        require(studentIds[newStudentId] == address(0), "Student ID already exists");

        students[msg.sender] = Student({
            name: _name,
            rollNo: _rollNo,
            branch: _branch,
            studentId: newStudentId,
            reputation: 0,
            credits: 0,
            sharedResources: new uint256[](0)
        });

        // Map the new student ID to the student's address
        studentIds[newStudentId] = msg.sender;
    }

    // Add a new resource
    function addResource(string memory _title, string memory _description) public onlyRegisteredStudent {
        resourceCount++;
        resources[resourceCount] = Resource({
            title: _title,
            description: _description,
            creator: msg.sender,
            accessCount: 0
        });

        students[msg.sender].sharedResources.push(resourceCount);

        // Reward the student with credits for sharing a resource
        students[msg.sender].credits += 10;
    }

    // Access a resource
    function accessResource(uint256 _resourceId) public onlyRegisteredStudent {
        require(_resourceId > 0 && _resourceId <= resourceCount, "Resource does not exist");

        resources[_resourceId].accessCount++;

        // Reward the creator of the resource with credits and reputation
        address creator = resources[_resourceId].creator;
        students[creator].credits += 2;
        students[creator].reputation += 1;
    }

    // Get student profile by address
    function getStudentProfile(address _studentAddress) public view returns (string memory name, string memory rollNo, string memory branch, string memory studentId, uint256 reputation, uint256 credits, uint256[] memory sharedResources) {
        Student storage student = students[_studentAddress];
        return (student.name, student.rollNo, student.branch, student.studentId, student.reputation, student.credits, student.sharedResources);
    }

    // Get student profile by student ID
    function getStudentProfileById(string memory _studentId) public view returns (string memory name, string memory rollNo, string memory branch, string memory studentId, uint256 reputation, uint256 credits, uint256[] memory sharedResources) {
        address studentAddress = studentIds[_studentId];
        return getStudentProfile(studentAddress);
    }

    // Get resource details
    function getResourceDetails(uint256 _resourceId) public view returns (string memory title, string memory description, address creator, uint256 accessCount) {
        require(_resourceId > 0 && _resourceId <= resourceCount, "Resource does not exist");

        Resource storage resource = resources[_resourceId];
        return (resource.title, resource.description, resource.creator, resource.accessCount);
    }

    // Admin can reward students with additional credits
    function rewardStudent(address _studentAddress, uint256 _amount) public onlyAdmin {
        students[_studentAddress].credits += _amount;
    }

    // Students can redeem credits for rewards (for simplicity, just a placeholder function)
    function redeemCredits(uint256 _amount) public onlyRegisteredStudent {
        require(students[msg.sender].credits >= _amount, "Insufficient credits");

        // Deduct the credits
        students[msg.sender].credits -= _amount;

        // Logic for redeeming the credits can be implemented here
    }
}
