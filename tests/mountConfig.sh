#!/bin/sh

echo "
         ######################################
         ###      Mounting config test       ##
         ######################################
"


# Make sure tests fails if a command exits with non-zero
set -e

# shellcheck source=tests/.portconfig.sh
. $(dirname "$0")/.portconfig.sh

# Create config directory for testing
mkdir /tmp/test-mountConfig/ && sudo chown 10000 /tmp/test-mountConfig/

# Create docker container with our test parameters
DOCKERCONTAINER=$(docker run -d -v /tmp/test-mountConfig/:/inspircd/conf -p "127.0.0.1:${CLIENT_PORT}:6667" -p "127.0.0.1:${TLS_CLIENT_PORT}:6697" inspircd:testing)
sleep 5

# Check if config was created successfully
diff conf/inspircd.conf /tmp/test-mountConfig/inspircd.conf
echo quit | timeout 10 openssl s_client -ign_eof -connect "localhost:${TLS_CLIENT_PORT}"

# Make sure the internal healthcheck is working
sleep 28
[ "$(docker ps -f id="${DOCKERCONTAINER}" | grep -c \(healthy\))" -eq 1 ] || exit 1

# Clean up
docker stop "${DOCKERCONTAINER}" && docker rm "${DOCKERCONTAINER}"

