
# 🎲 Game Of Chance

<h4 align="center">
  <a href="#overview">Overview</a> |
  <a href="#quickstart">Quickstart</a> |
  <a href="#documentation">Documentation</a>
</h4>

This project implements a decentralized lottery system using Chainlink VRF (Verifiable Random Function) for randomness and Chainlink Price Feeds to ensure the lottery entry is pegged to a minimum USD value. Participants can fund the lottery, and a random winner is selected after a specified duration.

⚙️ Built using **Foundry**, **Scaffold-ETH2**, **Chainlink VRF**, and **Chainlink Price Feeds**.

- 🎰 **Randomness with Chainlink VRF**: Guarantees a verifiably random lottery outcome.
- 💲 **USD Pricing with Chainlink Price Feeds**: Ensures participants contribute a minimum amount in USD, regardless of ETH price volatility.
- 🔄 **Automatic Lottery Reset**: After every round, the lottery resets, allowing for continuous operation.
- 🔐 **Safe Fund Distribution**: Winnings are automatically sent to the lottery winner securely.

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- [Yarn](https://yarnpkg.com/getting-started/install)
- [Foundry](https://github.com/foundry-rs/foundry)
- [Git](https://git-scm.com/downloads)

## Quickstart

To get started with the Lottery Smart Contract, follow the steps below:

### 1. Install Dependencies

If you haven't installed dependencies already:

\`\`\`bash
yarn install
\`\`\`

### 2. Run a Local Ethereum Network

In the first terminal, run a local Ethereum network:

\`\`\`bash
yarn chain
\`\`\`

This starts a local blockchain using Foundry. You can customize the network configuration in `foundry.toml`.

### 3. Deploy the Lottery Contract

In the second terminal, deploy the contract:

\`\`\`bash
yarn deploy
\`\`\`

This deploys the `Lottery.sol` contract to the local network. The contract can be modified in `contracts/`.

### 4. Start the Frontend

In the third terminal, start the Next.js app:

\`\`\`bash
yarn start
\`\`\`

Visit your app at `http://localhost:3000` to interact with the lottery contract. You can monitor the contract's state and interactions via the web UI.

## Key Features

- **Fund the Lottery**: Participants can enter by sending a minimum amount of ETH, pegged to a USD value through Chainlink Price Feeds.
- **End the Lottery**: Automatically ends after 3 minutes and picks a winner using Chainlink VRF.
- **Distribute Winnings**: The smart contract transfers the entire lottery balance to the selected winner.

## Contract Details

### Lottery.sol

The primary contract of the system, `Lottery.sol`, manages:
- **Funding**: Users send ETH to enter the lottery.
- **Randomness**: Uses Chainlink VRF to ensure the winner is selected randomly.
- **Payouts**: Distributes the lottery funds to the winner automatically.

### PriceConverter.sol

A utility library, `PriceConverter.sol`, converts ETH amounts to USD using Chainlink Price Feeds. This ensures that all participants meet the minimum entry requirement in USD.

### Deploy.s.sol

The `Deploy.s.sol` script is used to deploy the Lottery contract. It configures the lottery with Chainlink Price Feeds and VRF settings, handling both local and live environments.

## Running Tests

You can run the tests using Foundry’s test framework:

\`\`\`bash
forge test
\`\`\`

The tests include mocks for the Chainlink Price Feeds and VRF for local testing.

## Deployment to Sepolia Testnet

To deploy the contracts to Sepolia, set up your `.env` file with the required variables:

\`\`\`bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
PRIVATE_KEY=YOUR_PRIVATE_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
\`\`\`

Then deploy:

\`\`\`bash
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
\`\`\`

## Documentation

For a detailed explanation of how the lottery works, as well as customization options, visit the project documentation:

- **Contract Documentation**: [Lottery.sol](contracts/Lottery.sol)
- **Price Converter**: [PriceConverter.sol](contracts/PriceConverter.sol)
- **Chainlink VRF**: [VRF Consumer Guide](https://docs.chain.link/docs/get-a-random-number/)
  
Check out Scaffold-ETH’s [documentation](https://docs.scaffoldeth.io) for more on how this project integrates with the Scaffold-ETH2 framework.
