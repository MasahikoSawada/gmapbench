./dobench.sh -t ext -S 1000 -T 180 -l 100 -i -C 16 -n 32 -u
./dobench.sh -t master -S 1000 -T 180 -l 100 -i -C 16 -n 32 -u
./dobench.sh -t ext -S 1000 -T 180 -l 100 -i -C 16 -n 32
./dobench.sh -t master -S 1000 -T 180 -l 100 -i -C 16 -n 32

./dobench.sh -t ext -S 1000 -T 180 -l 100 -i -C 64 -n 32
./dobench.sh -t master -S 1000 -T 180 -l 100 -i -C 64 -n 32
./dobench.sh -t ext -S 1000 -T 180 -l 100 -i -C 64 -n 32 -u
./dobench.sh -t master -S 1000 -T 180 -l 100 -i -C 64 -n 32 -u
