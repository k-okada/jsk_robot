#!/usr/bin/env roseus

(ros::load-ros-manifest "geometry_msgs")
(load "package://spoteus/spot-interface.l")
(spot-init)

(setq *pi* 3.14159265358979)

(setq *right-eye-topic* "/righteye_driver/look_at")
(setq *left-eye-topic* "/lefteye_driver/look_at")

(setq *right-eye-target* (instance geometry_msgs::Point :init))
(setq *left-eye-target* (instance geometry_msgs::Point :init))

(ros::advertise *right-eye-topic* geometry_msgs::Point 1)
(ros::advertise *left-eye-topic* geometry_msgs::Point 1)

(setq index 0)
(ros::rate 10)
(while (ros::ok)
       (ros::sleep)
       (send *right-eye-target* :x (* -1 (cos (/ (* 2 *pi* index) 10))))
       (send *right-eye-target* :y (* 1 (sin (/ (* 2 *pi* index) 10))))
       (send *left-eye-target* :x (* 1 (cos (/ (* 2 *pi* index) 10))))
       (send *left-eye-target* :y (* 1 (sin (/ (* 2 *pi* index) 10))))
       (ros::publish *right-eye-topic* *right-eye-target*)
       (ros::publish *left-eye-topic* *left-eye-target*)
       (ros::ros-info "publish to right ~A" *right-eye-target*)
       (ros::ros-info "publish to right ~A" *left-eye-target*)
       (setq index (+ 1 index))
       )
