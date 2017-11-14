#!/bin/sh
echo "
         ######################################
         ###     Secret custom conf test     ##
         ######################################
"


# Make sure tests fails if a command exits with non-zero
set -e

# shellcheck source=tests/.portconfig.sh
. $(dirname "$0")/.portconfig.sh

# Helpfunction for version compare
version_ge() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || test "$1" = "$2"; }

# Verify that the docker version allows secrets
version_ge "$(docker version --format '{{.Server.Version}}')" 1.13.0 || {
    echo "
         ################################################################
         ##                                                            ##
         ##   Docker version $(docker version --format '{{.Server.Version}}') doesn't allow to test secrets      ##
         ##   Docker version 1.13.0 or higher required for this test.  ##
         ##                                                            ##
         ################################################################
         "
    exit 0
}

TESTFILE="/tmp/tests-customConfig/test.conf"

mkdir -p "$(dirname $TESTFILE)"

echo "<module name=\"m_cban.so\">" >"$TESTFILE"

SECRETCONFIG=$(docker secret create test-config  "$TESTFILE")

# Run service with configs attached
DOCKERSERVICE=$(docker service create -q -d -p "${CLIENT_PORT}:6667" -p "${TLS_CLIENT_PORT}:6697" --secret source=test-config,target=test.conf inspircd:testing)

sleep 40


docker service logs "$DOCKERSERVICE" | grep "m_cban.so"

# Clean up
docker service rm "${DOCKERSERVICE}" && docker secret rm "$SECRETCONFIG"
