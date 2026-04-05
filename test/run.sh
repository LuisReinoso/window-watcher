#!/usr/bin/env bash
# Runs all bats tests in the test/ directory

set -e

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS="$TEST_DIR/bats-core/bin/bats"

if [[ ! -x "$BATS" ]]; then
    echo "bats not found at $BATS"
    echo "Run: git submodule update --init --recursive"
    exit 1
fi

"$BATS" "$TEST_DIR/unit/" "$TEST_DIR/integration/"
