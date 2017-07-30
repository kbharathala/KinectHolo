#!/bin/bash

mkdir -p build \
&& cd build \
&& make -j4 install

rm proto_cpp_bindings/*
protoc -I=../common/ --cpp_out=proto_cpp_bindings ../common/message.proto

echo "DONE :^)"
