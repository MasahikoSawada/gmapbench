\set aid random_gaussian(1, 100000 * , 2.0)
\set bid random_gaussian(1, 1 * , 2.0)
\set tid random_gaussian(1, 10 * , 2.0)
\set delta random_gaussian(-5000, 5000, 2.0)
BEGIN;
UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
END;
