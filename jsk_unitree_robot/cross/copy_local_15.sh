#!/bin/bash

# tar -cvzf /tmp/15-local.tgz --exclude /usr/local/cuda-10.2/samples --exclude /usr/local/cuda-10.2/doc --exclude /usr/local/cuda-10.2/nvvm/libnvvm-samples/ --exclude /usr/local/jetson_stats/ --exclude /usr/local/man --exclude /usr/local/share --exclude /usr/local/sbin  --exclude /usr/local/src --exclude /usr/local/games /usr/lib/aarch64-linux-gnu/libcud* /usr/lib/aarch64-linux-gnu/tegra /etc/alternatives/libcud* /usr/lib/aarch64-linux-gnu/libcublas* /usr/lib/aarch64-linux-gnu/libopenblas* /usr/local/ ~/.local/bin ~/.local/lib/

set -euf -o pipefail

LOCAL_DATA=15-local.tgz
if [ ! -e ${LOCAL_DATA} ]; then
    echo "Could not find ${LOCAL_DATA}"
    exit
fi

set -x
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "192.168.123.15" || echo "OK"
sshpass -p 123 ssh -o StrictHostKeyChecking=no unitree@192.168.123.15 exit
sshpass -p 123 ssh -t unitree@192.168.123.15 ls -al /usr/local/
sshpass -p 123 ssh -t unitree@192.168.123.15 ls -al /usr/local/lib/python3.6/dist-packages
sshpass -p 123 ssh -t unitree@192.168.123.15 ls -al /home/unitree/.local/bin /home/unitree/.local/lib
## manyally change /etc/sudoers
## # %sudo ALL=(ALL:ALL) ALL
## %sudo ALL=(ALL) NOPASSWD: ALL
cat ${LOCAL_DATA} | ssh -t unitree@192.168.123.15 sudo tar -C / --keep-old-files -xvzf -
