#!/usr/bin/env bash
# Puertos que necesita RustDesk OSS
set -e
ufw allow 21115:21119/tcp
ufw allow 21116/udp
ufw reload
