#!/bin/sh
for i in 1 2 3; do
    echo "Attempt opening http://web$i ..."
    curl http://web$i
done
