import strformat, strutils, os, times

proc fib(n: int): int =
    if n <= 2:
        return 1
    else:
        return fib(n - 1) + fib(n - 2)

when isMainModule:
    let n = if paramCount() >= 1: parseInt(paramStr(1)) else: 35
    let start = epochTime()
    let res = fib(n)
    let elapsed = epochTime() - start
    echo alignLeft("nim", 13), &" fib({n}) = {res} in {elapsed:.3f} s"
