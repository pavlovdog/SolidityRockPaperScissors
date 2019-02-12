const MainContract = artifacts.require('Main');

contract("Testing the admin functions", async (accounts) => {
  it("Checking pause functionality", async() => {
    const main = await MainContract.deployed();
  });
})
