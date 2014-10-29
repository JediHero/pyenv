#!/usr/bin/env bats

load test_helper
NUM_DEFINITIONS="$(ls "$BATS_TEST_DIRNAME"/../share/python-build | wc -l)"

@test "list built-in definitions" {
  run python-build --definitions
  assert_success
  assert_output_contains "2.7.8"
  assert_output_contains "jython-2.5.3"
  assert [ "${#lines[*]}" -eq "$NUM_DEFINITIONS" ]
}

@test "custom PYTHON_BUILD_ROOT: nonexistent" {
  export PYTHON_BUILD_ROOT="$TMP"
  assert [ ! -e "${PYTHON_BUILD_ROOT}/share/python-build" ]
  run python-build --definitions
  assert_success ""
}

@test "custom PYTHON_BUILD_ROOT: single definition" {
  export PYTHON_BUILD_ROOT="$TMP"
  mkdir -p "${PYTHON_BUILD_ROOT}/share/python-build"
  touch "${PYTHON_BUILD_ROOT}/share/python-build/2.7.8-test"
  run python-build --definitions
  assert_success "2.7.8-test"
}

@test "one path via PYTHON_BUILD_DEFINITIONS" {
  export PYTHON_BUILD_DEFINITIONS="${TMP}/definitions"
  mkdir -p "$PYTHON_BUILD_DEFINITIONS"
  touch "${PYTHON_BUILD_DEFINITIONS}/2.7.8-test"
  run python-build --definitions
  assert_success
  assert_output_contains "2.7.8-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 1))" ]
}

@test "multiple paths via PYTHON_BUILD_DEFINITIONS" {
  export PYTHON_BUILD_DEFINITIONS="${TMP}/definitions:${TMP}/other"
  mkdir -p "${TMP}/definitions"
  touch "${TMP}/definitions/2.7.8-test"
  mkdir -p "${TMP}/other"
  touch "${TMP}/other/3.4.2-test"
  run python-build --definitions
  assert_success
  assert_output_contains "2.7.8-test"
  assert_output_contains "3.4.2-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 2))" ]
}

@test "installing definition from PYTHON_BUILD_DEFINITIONS by priority" {
  export PYTHON_BUILD_DEFINITIONS="${TMP}/definitions:${TMP}/other"
  mkdir -p "${TMP}/definitions"
  echo true > "${TMP}/definitions/2.7.8-test"
  mkdir -p "${TMP}/other"
  echo false > "${TMP}/other/2.7.8-test"
  run bin/python-build "2.7.8-test" "${TMP}/install"
  assert_success ""
}

@test "installing nonexistent definition" {
  run python-build "nonexistent" "${TMP}/install"
  assert [ "$status" -eq 2 ]
  assert_output "python-build: definition not found: nonexistent"
}

@test "sorting Python versions" {
  export PYTHON_BUILD_ROOT="$TMP"
  mkdir -p "${PYTHON_BUILD_ROOT}/share/python-build"
  expected="2.7-dev
2.7.8-preview1
2.7.8-rc1
2.7.8-p0
2.7.8-p125
3.4.0
3.4.0-rc1
3.4.1
3.4.2
3.4-dev
2.2.0-dev
jython-2.5.0
jython-2.5.1
jython-2.5.2
jython-2.5.3
jython-2.5.4-rc1
jython-2.5-dev
jython-2.7-beta1
jython-2.7-beta2
jython-2.7-beta3
jython-dev"
  for ver in "$expected"; do
    touch "${PYTHON_BUILD_ROOT}/share/python-build/$ver"
  done
  run python-build --definitions
  assert_success "$expected"
}

@test "removing duplicate Python versions" {
  export PYTHON_BUILD_ROOT="$TMP"
  export PYTHON_BUILD_DEFINITIONS="${PYTHON_BUILD_ROOT}/share/python-build"
  mkdir -p "$PYTHON_BUILD_DEFINITIONS"
  touch "${PYTHON_BUILD_DEFINITIONS}/2.7.8"
  touch "${PYTHON_BUILD_DEFINITIONS}/3.4.2"

  run python-build --definitions
  assert_success
  assert_output <<OUT
2.7.8
3.4.2
OUT
}
