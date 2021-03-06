#!/bin/sh
echo "
         ######################################
         ###          Default test           ##
         ######################################
"


# Make sure tests fails if a command exits with non-zero
set -e

# shellcheck source=tests/.portconfig.sh
. $(dirname "$0")/.portconfig.sh

# Run container in a simple way
DOCKERCONTAINER=$(docker run -d -p "127.0.0.1:${CLIENT_PORT}:6667" -p "127.0.0.1:${TLS_CLIENT_PORT}:6697" inspircd:testing)

sleep 5

# Make sure TLS is working
echo quit | timeout 10 openssl s_client -ign_eof -connect "localhost:${TLS_CLIENT_PORT}"

sleep 28

# Make sure the internal healthcheck is working
[ "$(docker ps -f id="${DOCKERCONTAINER}" | grep -c \(healthy\))" -eq 1 ] || exit 1

# Make sure the container is not restarting
sleep 20
docker ps -f id="${DOCKERCONTAINER}"
sleep 20
docker ps -f id="${DOCKERCONTAINER}"

# Clean up
docker stop "${DOCKERCONTAINER}" && docker rm "${DOCKERCONTAINER}"
