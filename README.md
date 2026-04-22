# ERC20 template (Foundry + OpenZeppelin)

Production-oriented ERC-20 reference implementation using **Foundry** and **OpenZeppelin Contracts v5**. It includes owner-governed minting, holder burning, explicit `Mint`/`Burn` events for indexers, and **two-step ownership** (`Ownable2Step`) to reduce accidental ownership loss.

This repository is intended as an auditable starting point. **It is not a substitute for a security review** before mainnet use.

## Features

- **ERC20** + **ERC20Burnable** (holders burn their own balance)
- **Ownable2Step**: `transferOwnership` → pending owner → `acceptOwnership`
- **`mint(address to, uint256 amount)`**: `onlyOwner`
- **Events**: standard `Transfer` / `Approval`, plus **`Mint`** and **`Burn`** emitted from `_update` on mint/burn paths
- **Tests**: Forge unit + fuzz tests
- **Deploy**: `script/Deploy.s.sol` with environment-driven configuration

## Threat model and limitations

- **Owner key compromise** is catastrophic: the owner can mint arbitrary supply to any address.
- **Centralization**: this design is unsuitable if you need a fixed supply with no admin mint; consider burning admin rights after launch (not implemented here) or a different tokenomics model.
- **Not upgradeable**: the contract is **not** behind a proxy. Upgrades require a new deployment and migration.
- **No pause / blacklist**: omitted to keep scope minimal; add only with clear product and legal requirements.

## Dependencies (pinned, vendored)

| Package | Version | Source |
|--------|---------|--------|
| OpenZeppelin Contracts | v5.0.2 | [openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) |
| forge-std | v1.9.4 | [forge-std](https://github.com/foundry-rs/forge-std) |

Dependencies live under `lib/`. To refresh with Foundry instead:

```bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install foundry-rs/forge-std@v1.9.4 --no-commit
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`)

## Quick start

```bash
forge fmt
forge build
forge test -vvv
```
·
## Configuration

Copy `.env.example` to `.env` and set:

| Variable | Description |
|----------|-------------|
| `PRIVATE_KEY` | Deployer key (pays gas). Use a dedicated key; prefer hardware wallet workflows in production. |
| `RPC_URL` | HTTPS RPC for your target network. |
| `TOKEN_NAME` | ERC-20 name string. |
| `TOKEN_SYMBOL` | ERC-20 symbol string. |
| `INITIAL_OWNER` | Address receiving `Ownable` rights (often a multisig; may differ from deployer). |

Never commit `.env` or real keys.

## Deploy

Dry run (simulation):

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL"
```

Broadcast (sends transactions):

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --broadcast
```

Foundry loads variables from `.env` in the project root when present.

## Verify on a block explorer

After deployment, verify the contract (replace placeholders):

```bash
forge verify-contract \
  <DEPLOYED_ADDRESS> \
  src/MyToken.sol:MyToken \
  --chain <chain_id> \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  --constructor-args $(cast abi-encode "constructor(string,string,address)" "$TOKEN_NAME" "$TOKEN_SYMBOL" "$INITIAL_OWNER")
```

Exact flags depend on the verifier (Etherscan, Blockscout, Sourcify). See [Foundry: Verifying contracts](https://book.getfoundry.sh/forge/deploying.html#verifying-contracts).

## Project layout

| Path | Purpose |
|------|---------|
| `src/MyToken.sol` | Token implementation |
| `test/MyToken.t.sol` | Tests |
| `script/Deploy.s.sol` | Deployment script |
| `foundry.toml` | Solidity 0.8.24, optimizer, `evm_version` |

## Mainnet checklist (non-exhaustive)

1. Run tests and `forge fmt --check` in CI.
2. Deploy and verify on a **public testnet** first.
3. Use a **multisig** or robust custody for `INITIAL_OWNER`.
4. Plan incident response if the owner key is lost or leaked.
5. Engage independent **audit** for material value at risk.

## License

This template is released under the [MIT License](LICENSE).

## Acknowledgments

Built with [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) and [Foundry](https://github.com/foundry-rs/foundry).
