pragma solidity ^0.8.0;

contract DAO {
	/**
     * 1. Collects investors money (ether)
     * 2. Keep track of investor contributions with shares
     * 3. Allow investors to transfer shares
     * 4. Allow investment proposals to be created and voted
     * 5. Execute successful investment proposal (i.e. send money)
    */
    mapping(address => bool) public investors;
    mapping(address => uint) public shares;
    uint public totalShares;
    uint public availableFunds;
    uint public contributionEnd;
    
    constructor(uint contributionTime) {
        contributionEnd = block.timestamp + contributionTime;
    }
    
    function contribute() payable external {
        require(contributionEnd > block.timestamp, "cannot contribute after contribution is end");
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }
    
    function redeemShare(uint amount) external payable {
        require(shares[msg.sender] >= amount, "not enought shares");
        require(availableFunds >= amount, "not enought availableFunds");
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }	
}
