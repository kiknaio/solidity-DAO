const { expect, should, assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const DaoContract = artifacts.require('DAO');

contract('DAO', (accounts) => {
	let instance;
	
	beforeEach(async () => {
		instance = await DAO.new();	
	});
});
