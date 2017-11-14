#!/bin/sh

echo "
         ######################################
         ###          Secrets test           ##
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


# Generate certificates
cat > "/tmp/test-secrets-cert.template" <<EOF
XZ
Example State
Example City
Example IRC Network
Secret Server Admins
irc.example.com
nomail@example.com
EOF

# shellcheck disable=SC2002
cat "/tmp/test-secrets-cert.template" | openssl req -x509 -nodes -newkey rsa:4096 -keyout "/tmp/test-secrets-key.pem" -out "/tmp/test-secrets-cert.pem" -days 365 2>/dev/null

# Create secrets
SECRETCERT=$(docker secret create test-secrets-cert /tmp/test-secrets-cert.pem)
SECRETKEY=$(docker secret create test-secrets-key  /tmp/test-secrets-key.pem)

# Run container in a simple way
DOCKERSERVICE=$(docker service create -q -d -p "${CLIENT_PORT}:6667" -p "${TLS_CLIENT_PORT}:6697" --secret source=test-secrets-key,target=inspircd.key --secret source=test-secrets-cert,target=inspircd.crt inspircd:testing)
sleep 35
# Make sure TLS is working
TLSCHECK=$(echo quit | timeout 10 openssl s_client -ign_eof -connect "localhost:${TLS_CLIENT_PORT}" 2>/dev/null | grep -c "OU=Secret Server Admins")
[ "$TLSCHECK" -gt 0 ] || exit 1

sleep 5
# Clean up
docker service rm "${DOCKERSERVICE}" && docker secret rm "${SECRETCERT}" && docker secret rm "${SECRETKEY}"

