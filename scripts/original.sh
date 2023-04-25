#!/bin/bash
# from https://gist.github.com/pecigonzalo/66905b0839b88ce894eaf44846b85d65

# set -x

MANAGER=${1:-3}
WORKER=${2:-0}

#=========================
# Creating cluster members
#=========================
echo "### Creating $MANAGER managers"
for i in $(seq 2 "$MANAGER"); do
  docker run -d --privileged --name master-"${i}" --hostname=master-"${i}" -p "${i}"2375:2375 docker:stable-dind
done

echo "### Creating $WORKER workers"
for i in $(seq 1 "$WORKER"); do
  docker run -d --privileged --name worker-"${i}" --hostname=worker-"${i}" -p "${i}"3375:2375 docker:stable-dind
done

#===============
# Starting swarm
#===============
MANAGER_IP="172.17.0.1"
echo "### Initializing main master: localhost"
docker swarm init --advertise-addr "$MANAGER_IP"

#===============
# Adding members
#===============
MANAGER_TOKEN=$(docker swarm join-token -q manager)
WORKER_TOKEN=$(docker swarm join-token -q worker)

for i in $(seq 2 "$MANAGER"); do
  echo "### Joining manager: swarm-manager$i"
  docker --host=localhost:"${i}"2375 swarm join --token "${MANAGER_TOKEN}" "${MANAGER_IP}":2377
done
for i in $(seq 1 "$WORKER"); do
  echo "### Joining worker: swarm-manager$i"
  docker --host=localhost:"${i}"3375 swarm join --token "${WORKER_TOKEN}" "${MANAGER_IP}":2377
done

docker node ls