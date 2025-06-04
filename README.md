# Sample Polkadot Hardhat Project

If your flight is cancelled, we pay you immediately. InsuDot: Insurance without intermediaries..

## Contract Deployed

[Contract Address in Paseo](https://blockscout-passet-hub.parity-testnet.parity.io/address/0x1d66b4155C8689120cD9e40aBb7064e14F58ABEb?tab=index)

## Description

If your flight is cancelled, we pay you immediately. InsuDot: Insurance without intermediaries...

Currently, flight insurance is a necessity for anyone who wishes to travel with peace of mind. However, traditional processes for purchasing and managing flight insurance are often complex, expensive, and lack transparency. That is why we create InsuDot.

At InsuDot, we believe that blockchain technology can also improve the efficiency of the claims process. Our platform allows users to submit and track their claims quickly and easily, thanks to the traceability and transparency provided by blockchain technology.

With our innovative approach and utilization of cutting-edge technology, InsuDot has created a platform for selling flight insurance that is safer, more efficient, and more transparent than any other traditional flight insurance provider. Rest easy on your next trip with InsuDot.

This project demonstrates how to use Hardhat with Polkadot. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

1) Create a binary of the [`eth-rpc-adapter`](https://github.com/paritytech/polkadot-sdk/tree/master/substrate/frame/revive/rpc) and move it to `bin` folder at the root of your project. Alternatively, update your configuration file's `adapterConfig.adapterBinaryPath` to point to your local binary. For instructions, check [Polkadot Hardhat docs](https://papermoonio.github.io/polkadot-mkdocs/develop/smart-contracts/dev-environments/hardhat/#testing-your-contract).

2) Try running some of the following tasks:

```shell
npx hardhat test
npx hardhat node
npx hardhat node && npx hardhat ignition deploy ./ignition/modules/MyToken.js --network localhost
```

## Issues That I Have to Work With Polkadot Plugin

* [Docs](https://papermoonio.github.io/polkadot-mkdocs/develop/smart-contracts/dev-environments/hardhat/) Docs are good but not too clear in some parts

* Dependencies list: @parity/hardhat-polkadot@0.1.5, @parity/resolc
