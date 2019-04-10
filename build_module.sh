#!/bin/bash

nim c -d:release --app:lib --gc:regions --out:fib_nimpy.so fib_nimpy.nim
