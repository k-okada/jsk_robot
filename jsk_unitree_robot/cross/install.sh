#! /bin/bash

usage() { echo "Usage: $0 [-p password ] [-d <User|System>]" 1>&2; exit 1; }

TARGET_DIRECTORY=User
PASS=""

while getopts "p:d:" o; do
    case "${o}" in
        p)
            PASS=${OPTARG}
            ;;
        d)
            TARGET_DIRECTORY=${OPTARG}
            [[ ${TARGET_DIRECTORY} == "User" || ${TARGET_DIRECTORY} == "System" ]] || usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

TARGET_MACHINE="${TARGET_MACHINE:-arm64v8}"

set -euf -o pipefail

# Check if ros has been cross-compilled
if [ ! -d "$(pwd)/${TARGET_MACHINE}_${TARGET_DIRECTORY}" ]; then
    echo "ERROR: System directory is not found" 1>&2
    echo "ERROR: please build ros for pepper first" 1>&2
    exit 1
fi

# Get password

# Receive pepper hostname or ip
echo 'Automatic install script for ros unitree Go1 \n'
echo "!!! CAUTION !!! If you modifeid files in the Go1, it will be removed/overwrited"

function copy_data () {
    user=$1
    hostname=$2

    if [ "${PASS}" == "" ]; then
        echo "Enter password for ${hostname} : "
        read PASS
    fi

    echo "Copy ${TARGET_MACHINE}_${TARGET_DIRECTORY} ...."
    echo "==="
    du -sh ${TARGET_MACHINE}_${TARGET_DIRECTORY}
    echo "==="

    echo "  ... to ${user}@${hostname}:~/opt/jsk"
    echo "==="
    sshpass -p $PASS ssh -t ${user}@${hostname} bash -c 'df\ -h'
    echo "==="

    # Check if pepper is reachable
    reachability=$(ping -c4 ${hostname} 2>/dev/null | awk '/---/,0' | grep -Po '[0-9]{1,3}(?=% packet loss)')

    if [ -z "$reachability" ] || [ "$reachability" == 100 ]; then
        echo "ERROR: ${hostname} unreachable" 1>&2
        exit 2
    fi

    # check if we have jsk_startup in .startlist
    sshpass -p $PASS ssh -t ${user}@${hostname} "cat ~/Unitree/autostart/.startlist.sh"
    sshpass -p $PASS ssh -t ${user}@${hostname} "cat ~/Unitree/autostart/.startlist.sh | grep jsk_startup" ||
        sshpass -p $PASS ssh -t ${user}@${hostname} "sed -i -E -e '/^sportMode|imageai/a jsk_startup' Unitree/autostart/.startlist.sh"

    # check if we have /opt/jsk
    set -x
    sshpass -p $PASS ssh -t ${user}@${hostname} "test -e /opt/jsk" || \
        sshpass -p $PASS ssh -t ${user}@${hostname} "sudo mkdir -p /opt/jsk && sudo chown -R \$(id -u \${USER}):\$(id -g \${USER}) /opt/jsk && ls -al /opt/jsk"

    rsync --rsh="/usr/bin/sshpass -p $PASS ssh -o StrictHostKeyChecking=no -l ${user}" -avz --delete --exclude "*.pyc" --exclude "^logs/" ${TARGET_MACHINE}_${TARGET_DIRECTORY}/ ${hostname}:/opt/jsk/${TARGET_DIRECTORY}
    if [[ "${TARGET_DIRECTORY}" == "User" ]]; then
        rsync --rsh="/usr/bin/sshpass -p $PASS ssh -o StrictHostKeyChecking=no -l ${user}" -avz --delete ../jsk_unitree_startup/autostart/ ${hostname}:Unitree/autostart/jsk_startup
        # https://stackoverflow.com/questions/23395363/make-patch-return-0-when-skipping-an-already-applied-patch
        ### OUT="$(patch -p0 --backup --forward live_human_pose.py < publish_human_pose.diff)" || echo "${OUT}" | grep "Skipping patch" -q || (echo "$OUT" && false);
    fi
    set +x
}

copy_data pi 192.168.123.161
copy_data unitree 192.168.123.14
