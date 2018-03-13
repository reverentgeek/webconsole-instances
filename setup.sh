#!/bin/bash
set -e -o pipefail

help() {
    echo
    echo 'Usage ./setup.sh ~/path/to/TRITON_PRIVATE_KEY ~/path/to/CA_CRT ~/path/to/SERVER_KEY ~/path/to/SERVER_CRT'
    echo
    echo 'Checks that your Triton environment is sane and configures'
    echo 'an environment file to use.'
    echo
    echo 'TRITON_PRIVATE_KEY is the filesystem path to an SSH private key'
    echo 'used to connect to Triton.'
    echo
    echo 'CA_CRT is the filesystem path to a certificate authority crt file.'
    echo
    echo 'SERVER_KEY is the filesystem path to a TLS server key file.'
    echo
    echo 'SERVER_CRT is the filesystem path to a TLS server crt file.'
    echo
}

# Check for correct configuration
check() {

    if [ -z "$1" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'Please provide a path to a SSH private key to access Triton.'
        tput sgr0 # clear

        help
        exit 1
    fi

    if [ ! -f "$1" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'SSH private key for Triton is unreadable.'
        tput sgr0 # clear

        help
        exit 1
    fi

    # Assign args to named vars
    TRITON_PRIVATE_KEY_PATH=$1


    if [ -z "$2" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'Please provide a path to the NGINX CA crt file.'
        tput sgr0 # clear

        help
        exit 1
    fi

    if [ ! -f "$2" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'CA certificate for NGINX is unreadable.'
        tput sgr0 # clear

        help
        exit 1
    fi

    NGINX_CA_CRT_PATH=$2


    if [ -z "$3" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'Please provide a path to the server key file.'
        tput sgr0 # clear

        help
        exit 1
    fi

    if [ ! -f "$3" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'Server key file for NGINX is unreadable.'
        tput sgr0 # clear

        help
        exit 1
    fi

    NGINX_SERVER_KEY_PATH=$3


    if [ -z "$4" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'Please provide a path to the server crt file.'
        tput sgr0 # clear

        help
        exit 1
    fi

    if [ ! -f "$4" ]; then
        tput rev  # reverse
        tput bold # bold
        echo 'Server crt file for NGINX is unreadable.'
        tput sgr0 # clear

        help
        exit 1
    fi

    NGINX_SERVER_CRT_PATH=$4

    command -v triton >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! Joyent Triton CLI is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://www.joyent.com/blog/introducing-the-triton-command-line-tool'
        exit 1
    }

    TRITON_USER=$(triton profile get | awk -F": " '/account:/{print $2}')
    TRITON_DC=$(triton profile get | awk -F"/" '/url:/{print $3}' | awk -F'.' '{print $1}')
    TRITON_ACCOUNT=$(triton account get | awk -F": " '/id:/{print $2}')

    SDC_URL=$(triton env | grep SDC_URL | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')
    SDC_ACCOUNT=$(triton env | grep SDC_ACCOUNT | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')
    SDC_KEY_ID=$(triton env | grep SDC_KEY_ID | awk -F"=" '{print $2}' | awk -F"\"" '{print $2}')

    rm -f _env_consul
    rm -f _env

    echo '# Consul discovery via Triton CNS' >> _env_consul
    echo CONSUL=webconsole-instances-consul.svc.${TRITON_ACCOUNT}.${TRITON_DC}.joyent.com >> _env_consul
    echo CONSUL_AGENT=1 >> _env_consul
    echo >> _env_consul

    TRITON_CREDS_PATH=/root/.triton

    echo '# Site URL' >> _env
    echo BASE_URL=https://webconsole-instances.svc.${TRITON_ACCOUNT}.${TRITON_DC}.triton.zone >> _env
    echo COOKIE_DOMAIN=triton.zone >> _env
    echo >> _env

    echo PORT=8080 >> _env
    echo 'COOKIE_PASSWORD='$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 36) >> _env
    echo COOKIE_SECURE=1 >> _env
    echo COOKIE_HTTP_ONLY=1 >> _env
    echo SDC_KEY_PATH=/root/.ssh/id_rsa >> _env
    echo TRITON_CREDS_PATH=${TRITON_CREDS_PATH} >> _env
    echo SDC_URL=${SDC_URL} >> _env
    echo SDC_ACCOUNT=${SDC_ACCOUNT} >> _env
    echo SDC_KEY_ID=${SDC_KEY_ID} >> _env
    echo CONSUL=webconsole-instances-consul.svc.${TRITON_ACCOUNT}.${TRITON_DC}.joyent.com >> _env

    echo SDC_KEY=$(cat "${TRITON_PRIVATE_KEY_PATH}" | tr '\n' '#') >> _env
    echo SDC_KEY_PUB=$(cat "${TRITON_PRIVATE_KEY_PATH}".pub | tr '\n' '#') >> _env

    echo NGINX_CA_CRT=$(cat "${NGINX_CA_CRT_PATH}" | tr '\n' '#') >> _env
    echo NGINX_SERVER_KEY=$(cat "${NGINX_SERVER_KEY_PATH}" | tr '\n' '#') >> _env
    echo NGINX_SERVER_CRT=$(cat "${NGINX_SERVER_CRT_PATH}" | tr '\n' '#') >> _env

    echo >> _env
    echo NODE_ENV=production >> _env
    echo HEALTH_ENDPOINT=check-it-out >> _env
    echo NGINX_CONFIG=/etc/nginx/nginx.conf >> _env
    echo NODE_START=node index.js >> _env
    echo >> _env
}

# ---------------------------------------------------
# parse arguments

# Get function list
funcs=($(declare -F -p | cut -d " " -f 3))

until
    if [ ! -z "$1" ]; then
        # check if the first arg is a function in this file, or use a default
        if [[ " ${funcs[@]} " =~ " $1 " ]]; then
            cmd=$1
            shift 1
        else
            cmd="check"
        fi

        $cmd "$@"
        if [ $? == 127 ]; then
            help
        fi

        exit
    else
        help
    fi
do
    echo
done
