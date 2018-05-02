#!/bin/sh

#
# Usage:
# -t = targate
# -T = duration
#

while getopts "t:T:c:j:b:" opts
do
    case $opts in
	t)
	    TARGET=$OPTARG
	    ;;
	T)
	    DURATION=$OPTARG
	    ;;
	c)
	    CLIENTS=${OPTARG:-10}
	    ;;
	j)
	    JOBS=${OPTARG:-10}
	    ;;
	b)
	    BASE=${OPTARG}
	    ;;
    esac
done

if [ "$TARGET" == "" -o "$DURATION" == "" -o "$BASE" == "" ]; then
	echo "argument error."
	exit
fi

source ~/.bash_profile
##################################
P="p $TARGET"
SAMPLING_INTERVAL=1
SAMPLING_COUNT=$(($DURATION / $SAMPLING_INTERVAL))
PGBENCH="/nvme/${TARGET}/bin/pgbench"
HOME="~/pgsql/bench"
STATUSFILE="${HOME}/STATUS"
##################################

########### SETTING ##############
DIR="`date +"%Y%m%d_%H%M%S"`_${BASE}_${TARGET}"
C=${CLIENTS}		# clients
T=${DURATION}		# duration
J=${JOBS}		# threads
F_GAU="/home/masahiko/pgsql/bench/eval/gaussian_bench.sql"	# script (gaussian)
F_UNI="/home/masahiko/pgsql/bench/eval/uniformly_bench.sql"	# script (uniformly)
PREFIX="${DIR}"		# log prefix
RATE=0.2		# sampling rate
OUT_FILE="${DIR}/${TARGET}_d${DURATION}_mon"
PSQL="/nvme/${TARGET}/bin/psql -d postgres -p `s_to_port ${TARGET}`"
##################################

use ${BASE}
mkdir ${DIR}

echo "

------ CONFIGURATIONS -----------
base	   = \"${BASE}\"
target     = \"${TARGET}\"
duration   = \"${DURATION}\"
clients    = \"${CLIENTS}\"
jobs       = \"${JOBS}\"
output dir = \"${DIR}\"
rate       = \"${RATE}\"
--------------------------------
" | tee ${DIR}/pgbench_result.txt

scale=`${PSQL} -X -Atqc "select count(*) from pgbench_branches"`

#### PREPARE TO BENCH ####
# Gen benchmark script dynamically
cat template/gaussian_bench.sql.template | sed -e "s/####/${scale}/g" > gaussian_bench.sql
cat template/uniformly_bench.sql.template | sed -e "s/####/${scale}/g" > uniformly_bench.sql

# Run checkpoint before restarting
p ${TARGET} -c "checkpoint"

# truncate log and restart
truncate "${PGBASE}/${TARGET}/data/log/postgresql.log" --size 0
restart ${TARGET}

# Kick sar command
SAR="sar -A -o ${OUT_FILE}.sar $SAMPLING_INTERVAL $SAMPLING_COUNT"
$SAR > /dev/null &
sar_pid=$!

# Kick sql command
{
    # write header
    echo "time,relname,n_live_tup,n_dead_tup,dead_tuple_ratio,relsize,relsize_pretty,vacuum_count,autovacuum_count" > ${OUT_FILE}.pg

    while true
    do
	${PSQL} -X -F "," -Atqc"
select
	to_char(now(), 'HH:MI:SS') as time,
	relname, n_live_tup, n_dead_tup,
	(n_dead_tup::float / (n_live_tup + n_dead_tup) * 100)::numeric(6,3) as dead_tuple_ratio,
	pg_relation_size(relid)::float / 1024 / 1024 as relsize,
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

PORT=`s_to_port $TARGET`

$PGBENCH \
    --log \
    --protocol=prepared \
    --no-vacuum \
    postgres \
    --client=$C \
    --time=$T \
    --port=$PORT \
    --file=${F_GAU}@5 \
    --file=${F_UNI}@1 \
    --aggregate-interval=1 \
    --log-prefix=${PREFIX} >> ${DIR}/pgbench_result.txt 2>&1 &
pgbench_pid=$!
##########################

trap "kill -9 ${pgbench_pid} ${pg_pid} ${sar_pid};" 2
echo "pg $pg_pid sar $sar_pid"

wait $pgbench_pid
kill -9 ${pg_pid} ${sar_pid}

### Finished bench marking!!! ###

# move pgbench file to eval directory
mv ${PREFIX}* ${DIR}

# save postgresql.log
cp ${PGBASE}/${TARGET}/data/log/postgresql.log ${DIR}
cat ${DIR}/postgresql.log | egrep "automatic vacuum of table \"postgres.public.pgbench_accounts\"|starting vacuum on \"pgbench_accounts\"" > ${DIR}/postgresql.autovac.log

# Generate graph
cd ${DIR}
SARFILE="${TARGET}_d${DURATION}_mon"
LC_TIME=C sar -A -f ${SARFILE}.sar > ${SARFILE}.sar.txt
# $1 = sar.txt, $2 = .pg, $3 = pgbench
ruby ../rsar.rb ${SARFILE}.sar.txt ${TARGET}_d${DURATION}_mon.pg ${PREFIX}.${pgbench_pid}
rm -f ${SARFILE}.sar ${SARFILE}.sar.txt

cd ..
