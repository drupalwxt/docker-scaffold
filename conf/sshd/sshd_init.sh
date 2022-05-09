#!/bin/sh

echo "Starting SSH..."
/usr/sbin/sshd

echo "Starting PHP-FPM..."
exec docker-php-entrypoint "$@"
