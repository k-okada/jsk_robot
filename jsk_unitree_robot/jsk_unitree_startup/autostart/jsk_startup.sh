#!/bin/bash
##############
# Author: kei
# Put AFTER sportMode/imageai in ~/Unitree/autostart/.startlist.sh
##############
sleep 2

source /opt/jsk/User/user_setup.bash

eval echo "[jsk_startup] starting... " $toStartlog
rosnode list $toStartlog

if [ "$ROS_IP" == "192.168.123.161" ];then
    (sleep 2; roslaunch --screen sound_play soundplay_node.launch sound_play:=robotsound) &
    (sleep 2; roslaunch --screen jsk_unitree_startup rwt_app_chooser.launch) &
fi

if [ "$ROS_IP" == "192.168.123.14" ];then
    (sleep 5; roslaunch jsk_unitree_startup unitree_bringup.launch network:=ethernet) &
fi

(sleep 10; eval echo "[jsk_startup] done... " $toStartlog)
(sleep 11; rosnode list $toStartlog)
