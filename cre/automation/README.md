# Aave Robots — CRE Automation Workflow

This workflow uses the Chainlink Runtime Environment (CRE) to automate Aave robot contracts. On each cron tick it calls `checkUpkeep` on every configured robot, and if work is needed it submits a signed CRE report to the `MailboxCRE` contract which forwards the `performUpkeep` call on-chain.

## Architecture

```
CRE Workflow (cron)
  └─ checkUpkeep(robot)          # off-chain read
       └─ [upkeep needed]
            └─ runtime.report()  # sign & encode payload
                 └─ writeReport → MailboxCRE.onReport()
                                       └─ robot.performUpkeep()
```

### MailboxCRE

`MailboxCRE` ([src/contracts/MailboxCRE.sol](../../src/contracts/MailboxCRE.sol)) is the on-chain receiver. It implements the CRE `IReceiver` interface and, on `onReport`, ABI-decodes the report into `(address target, bytes calldata)` and calls the target directly.

No caller or forwarder checks are enforced — this is intentional. The robot contracts themselves are permissionless (anyone can call `performUpkeep`), so restricting who may deliver a report provides no security benefit.

## Config files

Two configs are committed, one per environment:

| File | Target | Purpose |
|------|--------|---------|
| `config.production.json` | `production-settings` | Full set of robots |
| `config.staging.json` | `staging-settings` | For testing |

### Config schema

```jsonc
{
  "schedule": "*/5 * * * *",   // cron expression for how often to run
  "evms": [
    {
      "chainName": "ethereum-mainnet-base-1",      // CRE chain selector name
      "mailboxAddress": "0x...",                   // deployed MailboxCRE address
      "automations": [
        {
          "address": "0x...",                      // robot contract address
          "checkData": "0x",                       // passed to checkUpkeep (use "0x" if unused)
          "automationContractType": "chainlink"    // "chainlink" | "gelato"
        }
      ]
    }
  ]
}
```

`automationContractType` controls how the upkeep calldata is built:
- `"chainlink"` — the workflow encodes `performUpkeep(checkUpkeepResult.performData)`.
- `"gelato"` — `checkUpkeep` already returns the full encoded calldata, so it is forwarded as-is.

## Setup

If `bun` is not already installed, see https://bun.sh/docs/installation.

```bash
cd cre/automation && bun install
```

## Simulate

Run from the **project root** (`cre/` parent):

```bash
# staging (single robot)
cre workflow simulate ./automation --target=staging-settings

# production (all robots)
cre workflow simulate ./automation --target=production-settings
```

Simulation performs the full off-chain logic including `checkUpkeep` reads and gas estimation, but does not submit any transactions.

## Deploy

```bash
# staging
cre workflow deploy ./automation --target=staging-settings

# production
cre workflow deploy ./automation --target=production-settings
```

The workflow name is set in `workflow.yaml` (`automation-staging` / `automation-production`). Deploying again with the same name updates the existing workflow.

## Adding a new robot

1. Add an entry to the `automations` array in `config.production.json` (and optionally `config.staging.json`):

```json
{
  "address": "0x<robot-address>",
  "checkData": "0x",
  "automationContractType": "chainlink"
}
```

2. Make sure a `MailboxCRE` is deployed on that chain and its address is set as `mailboxAddress`.

3. Simulate, then deploy.
