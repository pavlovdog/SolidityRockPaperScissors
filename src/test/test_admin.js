const MainContract = artifacts.require('Main');
console.log(1);

contract("Testing the admin functions", async (accounts) => {
  it("Checking pause functionality", async() => {
    const main = await MainContract.deployed();
    console.log(1);
  });

})
