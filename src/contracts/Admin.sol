pragma solidity ^0.5.0;

contract Admin {
    address public adminAddress;
    uint256 public minAmount = 10;
    uint256 public maxAmount = 10000000000;
    uint256 public fee = 20;
    bool public paused = false;

    modifier onlyUnpaused {
        require(paused == false);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == adminAddress);
        _;
    }

    function changeAdmin(address newAdminAddress) public onlyOwner {
        adminAddress = newAdminAddress;
    }

    function setFee(uint256 newFee) public onlyOwner {
        require(newFee >= 0);
        require(newFee < 100);

        fee = newFee;
    }

    function setAdmountGap(
        uint256 newMinAmount,
        uint256 newMaxAmount
    ) public onlyOwner {
        require(newMinAmount >= 0);
        require(newMinAmount <= newMaxAmount);

        minAmount = newMinAmount;
        maxAmount = newMaxAmount;
    }

    function pauseGame() public onlyOwner {
        paused = true;
    }


    function unpauseGame() public onlyOwner {
        paused = false;
    }

    function withdraw(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
}
