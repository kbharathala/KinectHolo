#!/bin/bash

mkdir -p build \
&& cd build \
&& make -j4 install

echo "DONE :^)"
