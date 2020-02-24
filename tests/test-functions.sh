# Wrappers for the tests

die() { echo >&1 "$@" ; exit 1 ; }
warn() { echo >&1 "$@" ; }

TMP=`mktemp -d`

COVERAGE=python3-coverage
COSIGN="$COVERAGE run --include cosign -a ./cosign"


