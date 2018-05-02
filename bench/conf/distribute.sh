cp /home/masahiko/pgsql/bench/conf/postgresql.conf /nvme/master/data
cp /home/masahiko/pgsql/bench/conf/common.conf /nvme/master/data

cp /home/masahiko/pgsql/bench/conf/postgresql.conf /nvme/defer/data
cp /home/masahiko/pgsql/bench/conf/common.conf /nvme/defer/data

cp /home/masahiko/pgsql/bench/conf/postgresql.conf.gmap /nvme/gmap/data/postgresql.conf
cp /home/masahiko/pgsql/bench/conf/common.conf /nvme/gmap/data/
mkdir /nvme/gmap/data/pg_gmap
