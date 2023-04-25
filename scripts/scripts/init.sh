#!/bin/sh

check_result () {
    ___RESULT=$?
    if [ $___RESULT -ne 0 ]; then
        echo $1
        exit 1
    fi
}

docker_info="$(docker info --format '{{.Swarm.LocalNodeState}}')"

own_ip="$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)"
docker swarm init --advertise-addr="$own_ip"
check_result "failed to initialize swarm on $own_ip"