PY ?= .venv/bin/python
PYTEST ?= $(PY) -m pytest
JOBS ?= 8

.PHONY: test test-cpu test-gpu

test:      ## CPU tests in parallel, then GPU tests serially (through the executor)
	$(MAKE) test-cpu
	$(MAKE) test-gpu

test-cpu:  ## the GPU-free subset (what CI runs)
	$(PYTEST) -q -m "not gpu" -n $(JOBS)

test-gpu:
	$(PYTEST) -q -m gpu -n 0
