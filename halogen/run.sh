#!/bin/bash

if [[ "$1" == "--debug" && "$OSTYPE" == "darwin"* ]]; then
  CMD_STR="lldb -o run halogen"
elif  [[ "$1" == "--debug" && "$OSTYPE" == "linux-gnu" ]]; then
  CMD_STR="gdb -ex run halogen"
else
  CMD_STR="./halogen"
fi

cd install && LD_LIBRARY_PATH=$PWD/../of/lib-linux/release-x86_64-64:$LD_LIBRARY_PATH ./halogen
