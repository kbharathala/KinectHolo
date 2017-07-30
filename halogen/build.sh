#!/bin/bash

mkdir -p build \
&& cd build \
&& mkdir -p ../src/proto \
&& protoc -I=../../common/ --cpp_out=../src/proto ../../common/message.proto \
&& make -j4 install


echo "DONE :^)"
