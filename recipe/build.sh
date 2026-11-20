#!/bin/bash
set -euxo pipefail

pushd gridutils

# --host/--build let configure skip running test binaries when cross-compiling
./configure --prefix="${PREFIX}" --build="${BUILD}" --host="${HOST}"

make -j"${CPU_COUNT}"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || -n "${CROSSCOMPILING_EMULATOR:-}" ]]; then
    make -C test
fi

make install

popd
