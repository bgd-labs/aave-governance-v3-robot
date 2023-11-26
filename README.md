# Aave Governance V3 Robot

<img src="./docs/robot-v3-banner.jpg" alt="Aave Governance Robot Cover" width="100%" height="100%">

This repository contains the smart contracts and backend for automating governance actions of Aave Governance V3 using Chainlink Automation and Chainlink API. Actions the robot executes on the governance contracts are also public and could be executed by anyone in a permissionless way.

## Specifications

Extensive documentation about the architecture and design of the system can be found [HERE](./docs/overview.md).

## Setup instructions

All the information about the setup of the project and deployments can be found [HERE](./docs/setup.md).

## Deployed addresses

|  | Execution Chain Robot | Voting Chain Robot | Roots Consumer | Gov Chain Robot |
| --- | --- | --- | --- | --- |
| Ethereum | [0x365d47ceD3D7Eb6a9bdB3814aA23cc06B2D33Ef8](https://etherscan.io/address/0x365d47ceD3D7Eb6a9bdB3814aA23cc06B2D33Ef8) | [0x9aaB9F0b6E19907e346420Edc0d3029Edb5e8616](https://etherscan.io/address/0x9aaB9F0b6E19907e346420Edc0d3029Edb5e8616) | [0x2fa6f0a65886123afd24a575ae4554d0fce8b577](https://etherscan.io/address/0x2fa6f0a65886123afd24a575ae4554d0fce8b577) | [0x011824f238aee05329213d5ae029e899e5412343](https://etherscan.io/address/0x011824f238aee05329213d5ae029e899e5412343) |
| Polygon | [0x249396a890F89D47F89326d7EE116b1d374Fb3A9](https://polygonscan.com/address/0x249396a890F89D47F89326d7EE116b1d374Fb3A9) | [0xbe7998712402B6A63975515A532Ce503437998b7](https://polygonscan.com/address/0xbe7998712402B6A63975515A532Ce503437998b7) | [0xe77af99210ac55939e1ba0bfc6a9a20e1da73b25](https://polygonscan.com/address/0xe77af99210ac55939e1ba0bfc6a9a20e1da73b25) | - |
| Avalanche | [0x7B74938583Eb03e06042fcB651046BaF0bf15644](https://snowtrace.io/address/0x7B74938583Eb03e06042fcB651046BaF0bf15644) | [0x10E49034306EaA663646773C04b7B67E81eD0D52](https://snowtrace.io/address/0x10E49034306EaA663646773C04b7B67E81eD0D52) | [0x6264E51782D739caf515a1Bd4F9ae6881B58621b](https://snowtrace.io/address/0x6264E51782D739caf515a1Bd4F9ae6881B58621b) | - |
| Arbitrum | [0x64093fe5f8cf62afb4377cf7ef4373537fe9155b](https://arbiscan.io/address/0x64093fe5f8cf62afb4377cf7ef4373537fe9155b) | - | - | - |
| Optimism | [0xa0195539e21A6553243344A3BE6b874B5d3EC7b9](https://optimistic.etherscan.io/address/0xa0195539e21A6553243344A3BE6b874B5d3EC7b9) | - | - | - |
| Bnb | [0x870F5EBf5C13B73251283b2d883988066e2bb732](https://bscscan.com/address/0x870F5EBf5C13B73251283b2d883988066e2bb732) | - | - | - |

## License

Copyright © 2023, Aave DAO, represented by its governance smart contracts.

Created by [BGD Labs](https://bgdlabs.com/).

The default license of this repository is [BUSL1.1](./LICENSE), but all interfaces and the content of the [libraries folder](./src/contracts/libraries/) are open source, MIT-licensed.

**IMPORTANT**. The BUSL1.1 license of this repository allows for any usage of the software, if respecting the *Additional Use Grant* limitations, forbidding any use case damaging anyhow the Aave DAO's interests.
