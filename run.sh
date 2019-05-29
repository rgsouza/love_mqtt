#!/bin/bash

docker run \
    -it \
    --rm \
    --network="lua-network" \
    -v "$PWD/src/:/src" \
    brunoguic/lua:5.1_mqttlua \
    $@
    