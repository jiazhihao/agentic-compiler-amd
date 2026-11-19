PY ?= .venv/bin/python
PYTEST ?= $(PY) -m pytest
JOBS ?= 8

.PHONY: test test-cpu test-gpu baseline

test:      ## CPU tests in parallel, then GPU tests serially (through the executor)
	$(MAKE) test-cpu
	$(MAKE) test-gpu

test-cpu:  ## the GPU-free subset (what CI runs)
	$(PYTEST) -q -m "not gpu" -n $(JOBS)

test-gpu:   ## serial: timing tests must not share the host with other GPU tests
	$(PYTEST) -q -m gpu -n 0

baseline:   ## re-record tests/baselines/amdclang-gfx950.json
	$(PY) scripts/baseline.py
