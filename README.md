# subgraph-availability-oracle

A [nuthatch](https://github.com/nightswatchhq/nuthatch) nest: **The Graph's Subgraph Availability Oracle on Arbitrum**.

Oracles vote on whether a subgraph deployment is available. A deployment the oracles deny stops accruing indexing rewards, so this is the voting record behind who gets paid for serving what.

One binary, one config file, no graph-node, no gateway, no query fees.

## What it indexes

**Chain:** `arbitrum-one`. **1 contract**, **5 tables**.

| alias | address |
|---|---|
| `oracle` | `0x1cb555359319a94280acf85372ac2323aae2f5fd` |

Found the honest way: `RewardsManager.subgraphAvailabilityOracle()` names it on-chain.

## Verified

Indexed blocks **495,288,098 to 497,284,469** and sealed **1,035 events**, all of them `OracleVote`. The four administrative tables (`OracleSet`, `VoteTimeLimitSet`, and the two ownership events) are empty over that window, which is what you would expect of admin events on a settled contract.

## The views are the point here

**1,038 raw votes collapse to 13 current positions**, across 6 deployments and 4 oracles. Each oracle re-votes on the same deployment roughly 80 times: the raw table is a heartbeat, and the state is what you actually want.

```sh
nuthatch sql --dir . "SELECT * FROM deployment_votes"
nuthatch sql --dir . "SELECT * FROM denials"
```

| view | what it is |
|------|------------|
| `deployment_votes` | one row per (deployment, oracle), carrying that oracle's **latest** position and when it took it |
| `denials` | deployments with at least one oracle currently denying, most-denied first |

Both stop deliberately short of declaring a deployment denied. The contract applies a quorum to decide that and **the quorum is not in the event stream**, so inventing one here would produce a number that looked authoritative and was not. `denials` gives you `denied_by` alongside `oracles_voting`, because 2 of 2 and 2 of 8 are different facts and a bare deny count cannot tell them apart.

## What this is not

It is **not** the `qos-reo` entry on the catalogue, and it does not replace it. That entry wants two things:

- **GIP-0079's Rewards Eligibility Oracle**, which is undeployed. `rewardsEligibilityOracle()` reverts on both `SubgraphService` and `RewardsManager` (probed 2026-08-22).
- **Gateway quality-of-service telemetry**, which is published off-chain. No contract emits it, so no amount of indexing reaches it.

This is the one part of that neighbourhood that exists on-chain today.

## Run it

```sh
nuthatch init --from https://github.com/nightswatchhq/subgraph-availability-oracle
cd subgraph-availability-oracle
nuthatch dev --dir . --backfill 2000000 --seal-direct --window 20000
nuthatch sql --dir . "SELECT * FROM denials"
```

The endpoint in `nuthatch.toml` is keyless and public, so this file is publishable: a `nuthatch.toml` is pinned into the nest's content address and must never carry a credential. It is enough to follow the tip. A **backfill** wants archive depth it may not have: pass your own with `--rpc`, and check it first with `nuthatch doctor --rpc <url>`.

## Tables

```
oracle__oracle_vote
oracle__oracle_set
oracle__vote_time_limit_set
oracle__new_ownership
oracle__new_pending_ownership
```
