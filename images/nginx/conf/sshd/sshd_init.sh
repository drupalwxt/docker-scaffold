#!/bin/sh

echo "Starting SSH..."
/usr/sbin/sshd

echo "Starting Nginx..."
exec /docker-entrypoint.sh "$@"
