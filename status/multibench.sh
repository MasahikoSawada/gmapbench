./dobench.sh -t ext -S 10000 -T 180 -l 30 -i -C 4 -c 8
./dobench.sh -t ext -S 10000 -T 180 -l 30 -i -C 4 -c 16
./dobench.sh -t master -S 10000 -T 180 -l 30 -i -C 4 -c 8
./dobench.sh -t master -S 10000 -T 180 -l 30 -i -C 4 -c 16

./dobench.sh -t ext -S 10000 -T 180 -l 30 -i -C 16 -c 8
./dobench.sh -t ext -S 10000 -T 180 -l 30 -i -C 16 -c 16
./dobench.sh -t master -S 10000 -T 180 -l 30 -i -C 16 -c 8
./dobench.sh -t master -S 10000 -T 180 -l 30 -i -C 16 -c 16
