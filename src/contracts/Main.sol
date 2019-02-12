pragma solidity ^0.5.0;

import "./Oraclize.sol";
import './SafeMath.sol';
import './Admin.sol';

contract Main is Admin, usingOraclize {
    // Status field description:
    // - 0 means that the game is not exists (EVM set the 0 value by default, so let's use it as a feature)
    // - 1 means that the game has been initialized and we're waiting for payments from players
    // - 2 means that the both players have payed and we're waiting for Oracle desicion
    // - 3 means that the game has been completed
    struct Game {
        uint256 amount;
        address payable initializer;
        address payable opponent;
        bool initializerPayed;
        bool opponentPayed;
        uint8 initializerChoice;
        uint8 opponentChoice;
        uint8 status;
    }

    mapping (uint256 => Game) public games;
    mapping (bytes32 => uint256) public oraclizeQueryIds;
    mapping (string => uint8) oraclizeResponceToChoice;

    using SafeMath for uint;

    event Initialized(
        uint256 gameId
    );

    event Played(
        uint256 gameId,
        bytes32 oraclizeId
    );

    event Executed(
        uint256 gameId,
        uint256 initializerChoice,
        uint256 opponentChoice
    );

    constructor() public {
        adminAddress = msg.sender;

        oraclizeResponceToChoice['1'] = 1;
        oraclizeResponceToChoice['2'] = 2;
        oraclizeResponceToChoice['3'] = 3;

        oraclize_setCustomGasPrice(10000000000 wei);
    }

    function initializeGame(
        uint256 amount,
        address payable opponent,
        uint256 gameId
    ) onlyUnpaused public {
        require(games[gameId].status == 0);         // Check that the gameId has never been used before
        require(amount >= minAmount);               // Check that the provided amount is more than minimum
        require(amount <= maxAmount);               // Check that the provided amount is less than maximum
        require(gameId != 0);

        // Create new game
        games[gameId] = Game({
            amount: amount,
            initializer: msg.sender,
            opponent: opponent,
            initializerPayed: false,
            opponentPayed: false,
            initializerChoice: 0,
            opponentChoice: 0,
            status: 1
        });

        emit Initialized(gameId);
    }

    function oneChoiceToAnother(uint8 firstChoice) private view returns (uint256) {
        return uint(keccak256(abi.encodePacked(firstChoice, now)));
    }

    function platformFee(uint256 amount) view private returns(uint256) {
        return SafeMath.div(SafeMath.mul(fee, amount), 100);
    }

    function __callback(bytes32 id, string memory result) public {
        require(msg.sender == oraclize_cbAddress());
        require(oraclizeQueryIds[id] != 0);

        // The most simple way to receive the random choices for both players
        // is to execute 2 queries to the Oraclize. But it's too expensive :C
        // So we can save our money (and increase the game speed) by sending only 1 request
        // And retriving the second player choice somehow from it
        // For example - just execute the hash function on it

        uint256 gameId = oraclizeQueryIds[id];

        games[gameId].initializerChoice = oraclizeResponceToChoice[result];
        games[gameId].opponentChoice = uint8(oneChoiceToAnother(games[gameId].initializerChoice).mod(3) + 1);

        uint8 gameResult = rockPaperScissors(
            games[gameId].initializerChoice,
            games[gameId].opponentChoice
        );

        if (gameResult == 1) {          // Initializer win
            uint256 reward = games[gameId].amount.mul(2).sub(games[gameId].amount.mul(fee).div(100).mul(2));
            games[gameId].initializer.transfer(reward);
        } else if (gameResult == 2) {   // Opponet win
            uint256 reward = games[gameId].amount.mul(2).sub(games[gameId].amount.mul(fee).div(100).mul(2));
            games[gameId].opponent.transfer(reward);
        } else {                        // Draw
            uint256 reward = games[gameId].amount.sub(games[gameId].amount.mul(fee).div(100));
            games[gameId].initializer.transfer(reward);
            games[gameId].opponent.transfer(reward);
        }

        games[gameId].status = 3;

        emit Executed(gameId, games[gameId].initializerChoice, games[gameId].opponentChoice);
    }

    function executeGame(uint256 gameId) private {
        // Send request to the Oraclize
        bytes32 queryId = oraclize_query("WolframAlpha", "random choice {1 | 2 | 3}");
        oraclizeQueryIds[queryId] = gameId;

        // Set up new game's status
        games[gameId].status = 2;

        emit Played(gameId, queryId);
    }

    function playGame(uint256 gameId) onlyUnpaused payable public {
        // Check that the executor is initializer or opponet in this game
        require(msg.sender == games[gameId].initializer || msg.sender == games[gameId].opponent);
        // Check the provided amount is valid
        require(msg.value == games[gameId].amount);

        if (games[gameId].initializer == msg.sender) {
            // The initializer has already payed for this game, so return him the money
            if (games[gameId].initializerPayed == true) revert();
            games[gameId].initializerPayed = true;
        } else {
            // The opponent has already payed for this game, so return him the money
            if (games[gameId].opponentPayed == true) revert();
            games[gameId].opponentPayed = true;
        }


        if (
            games[gameId].opponentPayed
            && games[gameId].initializerPayed
            && games[gameId].status == 1
        ) {
            executeGame(gameId);
        }
    }

    // 1 - rock
    // 2 - paper
    // 3 - scissors
    function rockPaperScissors(
        uint8 firstChoice,
        uint8 secondChoice
    ) private pure returns (uint8) {
        if (firstChoice == 1 && secondChoice == 1) return 3;
        if (firstChoice == 1 && secondChoice == 2) return 2;
        if (firstChoice == 1 && secondChoice == 3) return 1;

        if (firstChoice == 2 && secondChoice == 1) return 1;
        if (firstChoice == 2 && secondChoice == 2) return 3;
        if (firstChoice == 2 && secondChoice == 3) return 2;

        if (firstChoice == 3 && secondChoice == 1) return 2;
        if (firstChoice == 3 && secondChoice == 2) return 1;
        if (firstChoice == 3 && secondChoice == 3) return 3;
    }
}
