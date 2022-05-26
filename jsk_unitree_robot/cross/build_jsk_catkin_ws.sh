#!/bin/bash

TARGET_MACHINE="${TARGET_MACHINE:-arm64v8}"
HOST_INSTALL_ROOT="${BASE_ROOT:-${PWD}}/"${TARGET_MACHINE}_System
INSTALL_ROOT=System
SOURCE_ROOT=${TARGET_MACHINE}_User

set -xeuf -o pipefail

# copy jsk_robot direcotry to jsk_catkin_ws/src
mkdir -p ${SOURCE_ROOT}/src/jsk_robot
for pkg in jsk_unitree_robot jsk_robot_common; do
    rsync -avzh --delete --exclude 'jsk_unitree_robot/cross*' ../../$pkg ${SOURCE_ROOT}/src/jsk_robot/$pkg
done
vcs import ${SOURCE_ROOT}/src < repos/unitree.repos

# run on docker
docker run -it --rm \
  -u $(id -u $USER) \
  -e INSTALL_ROOT=${INSTALL_ROOT} \
  -v ${HOST_INSTALL_ROOT}/ros1_dependencies:/opt/jsk/${INSTALL_ROOT}/ros1_dependencies:ro \
  -v ${HOST_INSTALL_ROOT}/Python:/opt/jsk/${INSTALL_ROOT}/Python:ro \
  -v ${HOST_INSTALL_ROOT}/ros1_inst:/opt/jsk/${INSTALL_ROOT}/ros1_inst:ro \
  -v ${HOST_INSTALL_ROOT}/startup_scripts:/opt/jsk/${INSTALL_ROOT}/startup_scripts:ro \
  -v ${HOST_INSTALL_ROOT}/setup.bash:/opt/jsk/${INSTALL_ROOT}/setup.bash:ro \
  -v ${PWD}/${SOURCE_ROOT}:/opt/jsk/User/jsk_catkin_ws:rw \
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
    source /opt/jsk/System/setup.bash && \
    env && \
    set -xeuf -o pipefail && \
    cd /opt/jsk/User/jsk_catkin_ws && \
    ROS_PACKAGE_PATH=src:\${ROS_PACKAGE_PATH} /home/user/rosinstall_generator_unreleased.py jsk_unitree_startup unitreeeus --rosdistro melodic --exclude RPP | tee jsk_catkin_ws.repos
    PYTHONPATH= vcs import src < jsk_catkin_ws.repos && \
    catkin build -vi \
    " 2>&1 | tee ${TARGET_MACHINE}_build_jsk_catkin_ws.log
cp ${PWD}/user_setup.bash ${SOURCE_ROOT}/
