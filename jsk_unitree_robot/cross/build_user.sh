#!/bin/bash

TARGET_MACHINE="${TARGET_MACHINE:-arm64v8}"
HOST_INSTALL_ROOT="${BASE_ROOT:-${PWD}}/"${TARGET_MACHINE}_System
INSTALL_ROOT=System
SOURCE_ROOT=${TARGET_MACHINE}_User

TARGET_ROBOT="${TARGET_ROBOT:-unitree}"

set -euf -o pipefail

for dir in $(find ${SOURCE_ROOT}/src/jsk_robot -maxdepth 1 -type d); do
    if [[ ! $dir =~ ${TARGET_ROBOT}|jsk_robot_common ]]; then
        touch $dir/CATKIN_IGNORE
    fi
done

UPDATE_SOURCE_ROOT=1  # TRUE
if [ -e "${SOURCE_ROOT}" ]; then
    echo "WARNING: Source directory is found ${SOURCE_ROOT}" 1>&2
    echo "WARNING: It might contain old data. We recommend to remove ${SOURCE_ROOT} and start again" 1>&2
    read -p "WARNING: Are you sure to continue [y/N] ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "WARNING: Exitting.."
        exit 1
    fi
    UPDATE_SOURCE_ROOT=0  # FALSE
fi

set -x
# copy jsk_robot direcotry to jsk_catkin_ws/src
mkdir -p ${SOURCE_ROOT}/src/jsk_robot
rsync -avzh --delete --exclude 'jsk_unitree_robot/cross*' ../../../jsk_robot ${SOURCE_ROOT}/src/
[ ${UPDATE_SOURCE_ROOT} -eq 0 ] || vcs import ${SOURCE_ROOT}/src < repos/unitree.repos

# run on docker
docker run -it --rm \
  -u $(id -u $USER) \
  -e INSTALL_ROOT=${INSTALL_ROOT} \
  -v ${HOST_INSTALL_ROOT}/ros1_dependencies:/opt/jsk/${INSTALL_ROOT}/ros1_dependencies:ro \
  -v ${HOST_INSTALL_ROOT}/Python:/opt/jsk/${INSTALL_ROOT}/Python:ro \
  -v ${HOST_INSTALL_ROOT}/ros1_inst:/opt/jsk/${INSTALL_ROOT}/ros1_inst:ro \
  -v ${HOST_INSTALL_ROOT}/startup_scripts:/opt/jsk/${INSTALL_ROOT}/startup_scripts:ro \
  -v ${HOST_INSTALL_ROOT}/system_setup.bash:/opt/jsk/${INSTALL_ROOT}/system_setup.bash:ro \
  -v ${PWD}/${SOURCE_ROOT}:/opt/jsk/User:rw \
  -v ${PWD}/rosinstall_generator_unreleased.py:/home/user/rosinstall_generator_unreleased.py:ro \
  ros1-unitree:${TARGET_MACHINE} \
  bash -c "\
    export CMAKE_PREFIX_PATH=\"/opt/jsk/${INSTALL_ROOT}/ros1_dependencies\" && \
    export PKG_CONFIG_PATH=\"/opt/jsk/${INSTALL_ROOT}/ros1_dependencies/lib/pkgconfig\" && \
    export LD_LIBRARY_PATH=\"/opt/jsk/${INSTALL_ROOT}/ros1_dependencies/lib:\${LD_LIBRARY_PATH}\" && \
    export PYTHONPATH=\"/opt/jsk/${INSTALL_ROOT}/ros1_dependencies/lib/python2.7/site-packages:\${PYTHONPATH}\" && \
    export LD_LIBRARY_PATH=\"/opt/jsk/${INSTALL_ROOT}/Python/lib:\${LD_LIBRARY_PATH}\" && \
    export PYTHONPATH=\"/opt/jsk/${INSTALL_ROOT}/Python/lib/python2.7/site-packages:\${PYTHONPATH}\" && \
    export PATH=\"/opt/jsk/${INSTALL_ROOT}/Python/bin:\${PATH}\" && \
    source /opt/jsk/System/system_setup.bash && \
    env && \
    set -xeuf -o pipefail && \
    cd /opt/jsk/User && \
    [ ${UPDATE_SOURCE_ROOT} -eq 0 ] || ROS_PACKAGE_PATH=src:\${ROS_PACKAGE_PATH} /home/user/rosinstall_generator_unreleased.py jsk_${TARGET_ROBOT}_startup ${TARGET_ROBOT}eus --rosdistro melodic --exclude RPP --exclude mongodb_store | tee user.repos && \
    echo 1000 && \
    [ ${UPDATE_SOURCE_ROOT} -eq 0 -o -z \"\$(cat user.repos)\" ] || PYTHONPATH= vcs import src < user.repos && \
    catkin build jsk_${TARGET_ROBOT}_startup ${TARGET_ROBOT}eus -s -vi \
    " 2>&1 | tee ${TARGET_MACHINE}_build_user.log
cp ${PWD}/user_setup.bash ${SOURCE_ROOT}/
