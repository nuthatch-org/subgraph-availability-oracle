-- The current state of the availability vote, per deployment per oracle.
--
-- Oracles vote on whether a subgraph deployment is *available*. A deployment the oracles deny stops
-- accruing indexing rewards, so this table is the record behind who gets paid for serving what.
--
-- A vote is not a verdict. Each oracle votes independently and can change its mind, so the raw table
-- holds the whole history and what matters is the *latest* vote each oracle cast for each deployment.
-- That is what this view computes: one row per (deployment, oracle), carrying that oracle's most
-- recent position and when it took it.
--
-- Deliberately stops short of declaring a deployment denied. The contract applies a quorum to decide
-- that, and the quorum is not in the event stream - inventing one here would produce a number that
-- looked authoritative and was not. `denied_by` below counts oracles currently voting deny; compare
-- it against the quorum yourself if you need the verdict.
CREATE VIEW deployment_votes AS
SELECT
  subgraphDeploymentID AS deployment,
  CAST(oracleIndex AS INTEGER) AS oracle,
  deny = 'true' AS denies,
  CAST(timestamp AS BIGINT) AS voted_at,
  block_number AS voted_in_block
FROM (
  SELECT *,
         row_number() OVER (PARTITION BY subgraphDeploymentID, oracleIndex
                            ORDER BY block_number DESC, log_index DESC) AS rn
  FROM oracle__oracle_vote
)
WHERE rn = 1;
