#/bin/bash

if [ $# -ne 3 ];then
	echo "argument error. target duration dir"
	exit
fi

source ~/.bash_profile

TARGET=$1
P="p $TARGET"
DURATION=$2
DIR=$3
SAMPLING_INTERVAL=1
SAMPLING_COUNT=$(($DURATION / $SAMPLING_INTERVAL))
OUT_FILE="${DIR}/${TARGET}_d${DURATION}_mon"
SAR="sar -A -o ${OUT_FILE}.sar $SAMPLING_INTERVAL $SAMPLING_COUNT"
PSQL="/nvme/${TARGET}/bin/psql -d postgres -p `s_to_port ${TARGET}`"

echo "int = $SAMPLING_INTERVAL cnt = $SAMPLING_COUNT"

# Kick sar command
$SAR > /dev/null &
sar_pid=$!
echo "sarPID = $sar_pid"

# Kick sql command
{
    trap 'exit' 1 2 9

    # write header
    echo "time,relname,n_live_tup,n_dead_tup,dead_tuple_ratio,relsize,relsize_pretty,vacuum_count,autovacuum_count" > ${OUT_FILE}.pg

    while true
    do
	${PSQL} -X -F "," -Atqc"
select
	to_char(now(), 'HH24:MM:SS') as time,
	relname, n_live_tup, n_dead_tup,
	(n_dead_tup::float / (n_live_tup + n_dead_tup) * 100)::numeric(6,3) as dead_tuple_ratio,
	pg_relation_size(relid) as relsize,
	pg_size_pretty(pg_relation_size(relid)) as relsize_pretty,
	vacuum_count, autovacuum_count
from
	pg_stat_user_tables
where
	relname in ('pgbench_accounts');
" >> ${OUT_FILE}.pg
	sleep $SAMPLING_INTERVAL
    done	
} &
pg_pid=$!
#echo "pgPID = $pg_pid"
trap "echo 'got'; kill -9 $sar_pid; kill -9 $pg_pid; break;" 2

# Wait until timeup
while true
do
    sleep 10
done

wait $pg_pid

# Kill other monitoring process
kill -9 $sar_pid
kill -9 $pg_pid

