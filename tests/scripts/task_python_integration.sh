#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -euxo pipefail

source tests/scripts/setup-pytest-env.sh
export LD_LIBRARY_PATH="build:${LD_LIBRARY_PATH:-}"

# to avoid CI CPU thread throttling.
export TVM_BIND_THREADS=0
export TVM_NUM_THREADS=2

# NOTE: also set by task_python_integration_gpuonly.sh.
if [ -z "${TVM_INTEGRATION_TESTSUITE_NAME:-}" ]; then
    TVM_INTEGRATION_TESTSUITE_NAME=python-integration
fi

# cleanup pycache
find . -type f -path "*.pyc" | xargs rm -f

# setup cython
cd python; python3 setup.py build_ext --inplace; cd ..

run_pytest ${TVM_INTEGRATION_TESTSUITE_NAME}-integration tests/python/integration

# forked is needed because the global registry gets contaminated
TVM_TEST_TARGETS="${TVM_RELAY_TEST_TARGETS:-llvm;cuda}" \
    run_pytest ${TVM_INTEGRATION_TESTSUITE_NAME}-relay tests/python/relay --ignore=tests/python/relay/aot

# OpenCL texture test. Deselected specific tests that fails  in CI
TVM_TEST_TARGETS="${TVM_RELAY_OPENCL_TEXTURE_TARGETS:-opencl}" \
    run_pytest ${TVM_INTEGRATION_TESTSUITE_NAME}-opencl-texture tests/python/relay/opencl_texture
# Command line driver test
run_pytest ${TVM_INTEGRATION_TESTSUITE_NAME}-driver tests/python/driver

# Target test
run_pytest ${TVM_INTEGRATION_TESTSUITE_NAME}-target tests/python/target
