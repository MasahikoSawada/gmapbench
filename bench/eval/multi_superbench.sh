source ~/.bash_profile

use nvme
./restore.sh nvme master &
r1=$!
./restore.sh nvme gmap &
r2=$!
echo "r1 = $r1 r2 = $r2"
trap "exit" 2 9

wait $r1 $r2

# master
start master
./superpgbench.sh -t master -T 600 -c 64 -j 4 -b nvme
p master -c "checkpoint"
stop master

# gmap
start gmap
./superpgbench.sh -t gmap -T 600 -c 64 -j 4 -b nvme
p gmap -c "checkpoint"
stop gmap

exit 


##################################################################

use hdd

./restore.sh hdd master
./restore.sh hdd gmap

# master
start master
./superpgbench.sh -t master -T 3600 -c 64 -j 4 -b hdd
p master -c "checkpoint"
stop master

# gmap
start gmap
./superpgbench.sh -t gmap -T 3600 -c 64 -j 4 -b hdd
p gmap -c "checkpoint"
stop gmap

