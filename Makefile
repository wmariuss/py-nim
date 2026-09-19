# Build the Nim pieces and run the three programs side by side.
#
# N is the Fibonacci index. It is the one knob worth turning: the gap between
# the rows widens with it, and the pure Python row is the one that hurts.
N      ?= 35
PYTHON ?= python3
MODULE := fib_nimpy.so
BIN    := fib_nim

# Nim 2 replaced --gc with --mm. orc is what nimpy tests against.
NIMFLAGS := c -d:release --mm:orc

.PHONY: all deps module binary bench check clean

all: module binary

deps:
	nimble install -d -y

module: $(MODULE)

binary: $(BIN)

# The shared object has to be named after the Nim module: nimpy generates
# PyInit_fib_nimpy, and that is the symbol CPython goes looking for.
$(MODULE): fib_nimpy.nim
	nim $(NIMFLAGS) --app:lib --out:$(MODULE) fib_nimpy.nim

$(BIN): fib_nim.nim
	nim $(NIMFLAGS) --out:$(BIN) fib_nim.nim

bench: $(MODULE) $(BIN)
	@$(PYTHON) fib_py3.py $(N)
	@$(PYTHON) fib_py3nim.py $(N)
	@./$(BIN) $(N)

# All three compute the same function, so all three owe the same answer.
check: $(MODULE) $(BIN)
	@a=$$($(PYTHON) fib_py3.py $(N) | awk '{print $$(NF-3)}'); \
	b=$$($(PYTHON) fib_py3nim.py $(N) | awk '{print $$(NF-3)}'); \
	c=$$(./$(BIN) $(N) | awk '{print $$(NF-3)}'); \
	echo "fib($(N)): python=$$a python+nim=$$b nim=$$c"; \
	if [ "$$a" != "$$b" ] || [ "$$b" != "$$c" ]; then echo "results disagree"; exit 1; fi

clean:
	rm -rf $(MODULE) $(BIN) nimcache __pycache__
