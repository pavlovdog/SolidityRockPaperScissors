# Rock, paper & scissors implementation in Solidity

This repo contains the Solidity source code for the "Rock, paper & scissors" game. The game is build with the Oraclize API, so users can be sure, that the result is truly random. Also, the `travis-cli` CI is enabled, for better development process.

The game process is pretty simple:

1. Some user creates the new game. He need to specify the game amount (in Wei), Ethereum address of the opponent and the game ID. Game ID should be the unique, otherwise, the exception will be raised. This should be done by calling the `initializeGame(uint256 amount, address opponent, uint256 gameId)` function.
2. Both users should send the exect amount, by calling the `playGame(uint256 gameId)` function.
3. During the second `playGame` call, the smart contract will automatically "execute" the game, by calling the Oraclize API. The call looks like `oraclize_query("WolframAlpha", "random choice {1 | 2 | 3}")`. It means, thet Oraclize should return the random string, which contains from one symbol: `1`, `2` or `3`. It's the same as `rock`, `paper`, `scissors`.
4. As you might guess, this string means the "choice" of the first player. After it has been receieved, we're retriving the second player's choice by hashing the first player choice and the timestamp of the previous block.
5. Depending on the choices, the smart contract will immidiatly sent the rewards to the players (minus comission, read the **FAQ** bellow).

## FAQ

### Why we're using Oraclize for generating the choices?

Let me give you an example. Imagine, that players should pass there solutions to the smart contract and the first one will be Alice. After Alice have sent her choice to the smart contract, her opponent - Bob, can easily get her choice from the blockchain and use the winning combination.

### Why we don't use the second Oraclize call for getting the second choice?

You may, but it's really expensive (here's the [Oraclize prising](http://docs.oraclize.it/#pricing-advanced-datasources-call-fee)). For now, one call for Wolfram Alpha API costs `0.03$`, which is quite a bit of.

### Who pays for Oraclize calls?

We have the `fee` parameter, which can be tuned by administrator. Be default, it equals to `20`, which means `20%`. So, the `amount * fee` Ethers from both deposits always stayed at the smart contract. Admin, can withdraw the Ethers, by calling the `withdraw(uint256 amount)` function.

### Who is the admin?

By default, it's the Ethereum account, which has deployed the contract to the network. You can also change the admin account by calling the `changeAdmin(address newAdminAddress)` function. Read the `contracts/Admin.sol` contract for more admin capabilities.

## Sequence diagram

![seq](https://github.com/pavlovdog/SolidityRockPaperScissors/blob/master/images/seq.svg)

## Run Truffle tests

```bash
npm install
cd src/
truffle test
```

## Compile source code with solc

```bash
cd SolidityRockPaperScissors/src/contracts
solc Main.sol --bin Admin.sol SafeMath.sol Oraclize.sol -o bin
```

## Get contract ABI with solc

```bash
cd SolidityRockPaperScissors/src/contracts
solc Main.sol --abi Admin.sol SafeMath.sol Oraclize.sol -o abi
```
