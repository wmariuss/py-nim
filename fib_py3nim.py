import time
from fib_nimpy import fib

if __name__ == "__main__":
    x = 47
    start = time.time()
    res = fib(x)
    elapsed = time.time() - start
    print("Py3+Nim Computed fib(%s)=%s in %0.2f seconds" % (x, res, elapsed))
