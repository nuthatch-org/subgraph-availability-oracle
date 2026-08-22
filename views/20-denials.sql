-- Deployments with at least one oracle currently voting to deny, most-denied first.
--
-- Built on `deployment_votes`, so it reflects each oracle's *latest* position rather than counting
-- every deny it has ever cast. `denied_by` is a count of oracles, not a verdict: whether that count
-- denies the deployment depends on the contract's quorum, which the event stream does not carry.
--
-- `oracles_voting` is the honest denominator. A deployment denied by 2 of 2 oracles that have looked
-- at it is a different thing from 2 of 8, and a bare deny count cannot tell them apart.
CREATE VIEW denials AS
SELECT
  deployment,
  count(*) FILTER (WHERE denies)     AS denied_by,
  count(*)                           AS oracles_voting,
  max(voted_at)                      AS last_vote_at,
  max(voted_in_block)                AS last_vote_block
FROM deployment_votes
GROUP BY deployment
HAVING count(*) FILTER (WHERE denies) > 0
ORDER BY denied_by DESC, last_vote_block DESC;
