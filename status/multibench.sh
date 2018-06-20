./dobench.sh -t ext -S 100 -T 180 -l 30 -i -C 16 -c 16 -u
./dobench.sh -t master -S 100 -T 180 -l 30 -i -C 16 -c 16 -u

./dobench.sh -t ext -S 100 -T 180 -l 30 -i -C 16 -c 32 -u
./dobench.sh -t master -S 100 -T 180 -l 30 -i -C 16 -c 32 -u

./dobench.sh -t ext -S 100 -T 180 -l 30 -i -C 16 -c 16
./dobench.sh -t master -S 100 -T 180 -l 30 -i -C 16 -c 16

./dobench.sh -t ext -S 100 -T 180 -l 30 -i -C 16 -c 32
./dobench.sh -t master -S 100 -T 180 -l 30 -i -C 16 -c 32

./dobench.sh -t ext -S 10000 -T 180 -l 30 -i -C 16 -c 32 -u
./dobench.sh -t master -S 10000 -T 180 -l 30 -i -C 16 -c 32 -u

./dobench.sh -t ext -S 10000 -T 180 -l 30 -i -C 32 -c 32 -u
./dobench.sh -t master -S 10000 -T 180 -l 30 -i -C 32 -c 32 -u
