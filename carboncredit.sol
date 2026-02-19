// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarbonCreditToken {
    string public name = "Carbon Credit Token";
    string public symbol = "CCT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    function mintTokens(address to, uint256 amount) external onlyOwner {
        uint256 value = amount * (10 ** uint256(decimals));
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}

/// --------------------
/// Minimal ERC721 (NFT)
/// --------------------
contract POSOCONFT {
    string public name = "POSOCO Registration NFT";
    string public symbol = "POSNFT";
    address public owner;
    uint256 public tokenCounter;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256[]) public tokensOfOwner;
    mapping(uint256 => string) public tokenURI;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    event Minted(address indexed to, uint256 indexed tokenId, string uri);

    constructor() {
        owner = msg.sender;
        tokenCounter = 0;
    }

    function mintCertificate(address to, string memory uri)
        public
        onlyOwner
        returns (uint256)
    {
        tokenCounter++;
        uint256 newId = tokenCounter;
        ownerOf[newId] = to;
        tokensOfOwner[to].push(newId);
        tokenURI[newId] = uri;
        emit Minted(to, newId, uri);
        return newId;
    }
}

/// --------------------
/// Main Carbon Registry
/// --------------------
contract CarbonRegistry {
    CarbonCreditToken public token;
    POSOCONFT public nftContract;

    address public posoco;
    address public bee;
    address public auditor;

    constructor(address _token, address _nft) {
        token = CarbonCreditToken(_token);
        nftContract = POSOCONFT(_nft);
        posoco = msg.sender;
    }

    struct Organization {
        string name;
        bool registered;
        bool nftIssued;
        uint256 nftId;
        uint256 totalEmissions;
        uint256 creditsEarned;
    }

    struct EmissionReport {
        uint256 year;
        uint256 emissionValue;
        bool verified;
    }

    mapping(address => Organization) public organizations;
    mapping(address => EmissionReport[]) public reports;

    modifier onlyPOSOCO() {
        require(msg.sender == posoco, "Only POSOCO");
        _;
    }

    modifier onlyBEE() {
        require(msg.sender == bee, "Only BEE");
        _;
    }

    modifier onlyAuditor() {
        require(msg.sender == auditor, "Only Auditor");
        _;
    }

    function setAuthorities(address _bee, address _auditor) external onlyPOSOCO {
        bee = _bee;
        auditor = _auditor;
    }

    function registerOrganization(address orgAddr, string memory orgName)
        external
        onlyPOSOCO
    {
        require(!organizations[orgAddr].registered, "Already registered");
        organizations[orgAddr] = Organization(orgName, true, false, 0, 0, 0);
    }

    function issueNFT(address orgAddr, string memory uri) external onlyPOSOCO {
        require(organizations[orgAddr].registered, "Not registered");
        require(!organizations[orgAddr].nftIssued, "NFT issued");

        uint256 nftId = nftContract.mintCertificate(orgAddr, uri);
        organizations[orgAddr].nftIssued = true;
        organizations[orgAddr].nftId = nftId;
    }

    function submitEmission(uint256 year, uint256 emissionValue) external {
        require(organizations[msg.sender].registered, "Not registered");
        reports[msg.sender].push(EmissionReport(year, emissionValue, false));
        organizations[msg.sender].totalEmissions += emissionValue;
    }

    function verifyEmission(address orgAddr, uint256 index, bool status)
        external
        onlyAuditor
    {
        require(index < reports[orgAddr].length, "Invalid index");
        reports[orgAddr][index].verified = status;
    }

    function rewardCredits(address orgAddr, uint256 amount)
        external
        onlyBEE
    {
        require(organizations[orgAddr].registered, "Org not found");
        token.mintTokens(orgAddr, amount);
        organizations[orgAddr].creditsEarned += amount;
    }

    function getOrgReports(address orgAddr)
        external
        view
        returns (EmissionReport[] memory)
    {
        return reports[orgAddr];
    }

    function getOrgDetails(address orgAddr)
        external
        view
        returns (Organization memory)
    {
        return organizations[orgAddr];
    }
}