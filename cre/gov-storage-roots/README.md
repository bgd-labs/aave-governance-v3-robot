# Aave Governance V3 — CRE Storage Roots Workflow

This workflow uses the Chainlink Runtime Environment (CRE) to submit Ethereum storage proofs to the DataWarehouse contract on the voting chain whenever a governance proposal's voting is activated.

## Architecture

```
CRE Workflow (log trigger: VotingActivated)
  └─ getProposal(proposalId)                    # read voting portal from governance
       └─ resolveVotingNetwork(votingPortal)     # map portal → chain + DataWarehouse
            └─ eth_getBlockByHash(snapshotHash)  # fetch block header via RPC
            └─ eth_getProof(AAVE, aAAVE, stkAAVE, Governance)
                 └─ processStorageRoot × 4       # submit account proofs
                 └─ processStorageSlot × 1       # submit stkAAVE exchange rate
                      └─ via MailboxCRE.onReport()
```

### How it works

1. **Trigger**: Listens for `VotingActivated(uint256 indexed proposalId, bytes32 indexed snapshotBlockHash, uint24 votingDuration)` events on the Aave Governance V3 contract on Ethereum.

2. **Resolve voting chain**: Reads the proposal from the governance contract to get the `votingPortal` address, then maps it to the corresponding voting network config (Ethereum, Avalanche, or Polygon).

3. **Fetch proofs**: Uses `ConfidentialHTTPClient` to call the Ethereum RPC (`eth_getBlockByHash` + `eth_getProof`) and retrieve:
   - Block header (RLP-encoded for on-chain verification)
   - Account proofs for AAVE, aAAVE, stkAAVE, and the Governance contract
   - Storage proof for the stkAAVE exchange rate slot

4. **Submit on-chain**: Sends 5 transactions to the DataWarehouse on the voting chain via `MailboxCRE`:
   - 4x `processStorageRoot` (one per account)
   - 1x `processStorageSlot` (stkAAVE exchange rate)

### MailboxCRE

`MailboxCRE` ([src/contracts/MailboxCRE.sol](../../src/contracts/MailboxCRE.sol)) is the on-chain receiver. It implements the CRE `IReceiver` interface and, on `onReport`, ABI-decodes the report into `(address target, bytes calldata)` and calls the target directly.

## Config files

Two configs are committed, one per environment:

| File | Target | Purpose |
|------|--------|---------|
| `config.production.json` | `production-settings` | Mainnet addresses |
| `config.staging.json` | `staging-settings` | For testing |

### Config schema

```jsonc
{
  "ethereumChainSelectorName": "ethereum-mainnet",
  "governanceAddress": "0x...",          // Aave Governance V3
  "tokens": {
    "aave": "0x...",                     // AAVE token
    "aAave": "0x...",                    // aAAVE token
    "stkAave": "0x..."                   // stkAAVE token
  },
  "votingNetworks": [
    {
      "votingPortalAddress": "0x...",    // VotingPortal contract on voting chain
      "chainSelectorName": "...",        // CRE chain selector name
      "dataWarehouseAddress": "0x...",   // DataWarehouse on voting chain
      "mailboxAddress": "0x..."          // MailboxCRE on voting chain
    }
  ]
}
```

## Secrets

The Ethereum RPC URL is stored as a CRE secret (not in config):

| Secret | Namespace | Description |
|--------|-----------|-------------|
| `ETH_RPC_URL` | `main` | Ethereum RPC for `eth_getBlockByHash` and `eth_getProof` |

Secrets are declared in [`cre/secrets.yaml`](../secrets.yaml) and uploaded to the Vault DON.

### Local simulation

Export the env var before simulating:

```bash
export ETH_RPC_URL="https://eth.llamarpc.com"
```

Or add it to `cre/gov-storage-roots/.env` and source it:

```bash
source cre/gov-storage-roots/.env
```

### Production — create a new secret

```bash
# 1. Export the secret value as an environment variable
export ETH_RPC_URL="<your-rpc-url>"

# 2. Upload to the Vault DON (reads env var names from secrets.yaml)
cre secrets create cre/secrets.yaml
```

### Production — update an existing secret

```bash
export ETH_RPC_URL="<new-rpc-url>"
cre secrets update cre/secrets.yaml
```

### Production — list and delete secrets

```bash
# List secrets (default namespace: main)
cre secrets list

# Delete secrets declared in secrets.yaml
cre secrets delete cre/secrets.yaml
```

## Setup

```bash
cd cre/gov-storage-roots && bun install
```

## Simulate

Run from the **project root** (`cre/` parent):

```bash
# staging
cre workflow simulate ./gov-storage-roots --target=staging-settings

# production
cre workflow simulate ./gov-storage-roots --target=production-settings
```

## Deploy

```bash
# staging
cre workflow deploy ./gov-storage-roots --target=staging-settings

# production
cre workflow deploy ./gov-storage-roots --target=production-settings
```
