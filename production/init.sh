#!/usr/bin/env bash
set -e

# Check http://geoffrey.io/a-php-development-environment-with-docker.html
# and https://github.com/eugeneware/docker-apache-php/blob/master/start.sh
# for more ideas as to how to use an init script.

cp /var/www/html/.env /tmp/
# Function to update the app configuration to make the service environment
# variables available.
function setEnvironmentVariable() {
    if [ -z "$2" ]; then
        echo "Environment variable '$1' not set."
        return
    fi

    # Check whether variable already exists
    if grep -q "\${$1}" /tmp/.env; then
        # Reset variable
        sed -i "s/\${$1}/$2/g" /tmp/.env
    fi
}

# Grep for variables that look like MySQL (MYSQL)
for _curVar in `env | grep MYSQL | awk -F = '{print $1}'`;do
    # awk has split them by the equals sign
    # Pass the name and value to our function
    setEnvironmentVariable ${_curVar} ${!_curVar}
done

#/usr/sbin/apache2ctl -D FOREGROUND
service apache2 restart
