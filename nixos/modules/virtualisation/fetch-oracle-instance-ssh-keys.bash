#!/usr/bin/env bash

set -euo pipefail

WGET() {
    wget --retry-connrefused -t 15 --waitretry=10 --header='Authorization: Bearer Oracle' "$@"
}

# When dealing with cryptographic keys, we want to keep things private.
umask 077
mkdir -p /root/.ssh

echo "Fetching authorized keys..."
WGET -O /root/.ssh/authorized_keys http://169.254.169.254/opc/v2/instance/metadata/ssh_authorized_keys
