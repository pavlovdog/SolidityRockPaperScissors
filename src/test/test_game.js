const MainContract = artifacts.require('Main');
console.log(1);

contract("Testing the game functionality", async(accounts) => {
  it("Creating the game", async() => {
    const main = await MainContract.deployed();
    console.log(1);
  });
})
