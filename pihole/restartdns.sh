#!/bin/bash

project="$(dirname "$(readlink -fm "$0")")"

docker-compose -f "${project}/docker-compose.yml" exec pihole pihole restartdns