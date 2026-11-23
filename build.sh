#!/bin/sh
#
# build.sh - builds fcalc with gfortran on Linux or macOS, and optionally
# runs the test scripts in tests/.
#
# Usage:  ./build.sh            build ./fcalc
#         ./build.sh test       build ./fcalc, then run every test script
#         ./build.sh clean      remove ./fcalc and the build directory
#
# Environment:
#   FC       the Fortran compiler (default gfortran)
#   FFLAGS   its flags (default "-std=f95 -O2")
#
# The modules are compiled in the order src/compiles.txt gives, each before
# the modules that USE it. src/gfortran/fcplatform.f90 takes the place of
# src/fcplatform.f90, which calls VMS's run-time library.

set -eu

cd "$(dirname "$0")"
here=$(pwd)

FC=${FC:-gfortran}
FFLAGS=${FFLAGS:--std=f95 -O2}

case "${1:-build}" in
    build|test) ;;
    clean)
        rm -rf build fcalc
        echo "cleaned"
        exit 0
        ;;
    *)
        echo "usage: $0 [build | test | clean]" >&2
        exit 2
        ;;
esac

# On macOS, gfortran's link needs the SDK's path to find library System.
if [ "$(uname -s)" = Darwin ] && [ -z "${SDKROOT:-}" ] && command -v xcrun >/dev/null 2>&1; then
    SDKROOT=$(xcrun --show-sdk-path)
    export SDKROOT
fi

if ! command -v "$FC" >/dev/null 2>&1; then
    echo "build.sh: $FC not found; install gfortran or set FC" >&2
    exit 1
fi

# The sources, in compiles.txt's order (module names in upper case there).
sources=""
for module in $(cat src/compiles.txt); do
    name=$(echo "$module" | tr '[:upper:]' '[:lower:]')
    if [ "$name" = fcplatform ]; then
        sources="$sources src/gfortran/fcplatform.f90"
    else
        sources="$sources src/$name.f90"
    fi
done

mkdir -p build
echo "$FC $FFLAGS -o fcalc ..."
# shellcheck disable=SC2086
"$FC" $FFLAGS -J build -o fcalc $sources
echo "fcalc built"

[ "${1:-build}" = test ] || exit 0

# Each script runs in one scratch directory holding tests/files, in the
# order of their names (the state script writes the files tests/expected
# holds). The date and time in a saved file's heading are masked.
work=$(mktemp -d "${TMPDIR:-/tmp}/fcalc-tests.XXXXXX")
trap 'rm -rf "$work"' EXIT
cp tests/files/* "$work"/

mask() {
    sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/YYYY-MM-DD hh:mm:ss/g' "$1"
}

passed=0
failed=0
check() {
    # check LABEL EXPECTED GOT
    mask "$2" > "$work/.want"
    mask "$3" > "$work/.got"
    if diff -u "$work/.want" "$work/.got" > "$work/.diff"; then
        echo "  ok    $1"
        passed=$((passed + 1))
    else
        echo "  FAIL  $1"
        cat "$work/.diff"
        failed=$((failed + 1))
    fi
}

echo "running tests"
for script in tests/*.in; do
    name=$(basename "$script" .in)
    (cd "$work" && "$here/fcalc" < "$here/$script" > "$work/$name.got" 2> "$work/$name.err") || true
    if [ -s "$work/$name.err" ]; then
        echo "  FAIL  $name (wrote to stderr)"
        cat "$work/$name.err"
        failed=$((failed + 1))
        continue
    fi
    check "$name" "tests/$name.out" "$work/$name.got"
done
for file in tests/expected/*; do
    name=$(basename "$file")
    if [ -f "$work/$name" ]; then
        check "$name" "$file" "$work/$name"
    else
        echo "  FAIL  $name (not written)"
        failed=$((failed + 1))
    fi
done

echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
