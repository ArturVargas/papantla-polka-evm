require('@nomicfoundation/hardhat-toolbox');

require('@parity/hardhat-polkadot');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.28',
  // npm Compiler
  resolc: {
    version: '1.5.2',
    compilerSource: 'npm',
    settings: {
      optimizer: {
        enabled: true,
        parameters: 'z',
        fallbackOz: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      polkavm: true,
    },
    polkadotHubTestnet: {
        polkavm: true,
        url: 'https://testnet-passet-hub-eth-rpc.polkadot.io',
        accounts: [process.env.PRIVATE_KEY],
      },
  },
};