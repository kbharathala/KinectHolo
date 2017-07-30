#!/bin/bash

mkdir -p build \
&& cd build \
&& mkdir -p ../src/proto_cpp_bindings \
&& protoc -I=../../common/ --cpp_out=../src/proto_cpp_bindings ../../common/message.proto \
&& make -j4 install


echo "DONE :^)"
