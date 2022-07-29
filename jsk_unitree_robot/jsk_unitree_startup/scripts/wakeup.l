#!/usr/bin/env roseus

(require :base64 "lib/llib/base64.l")
(ros::roseus-add-msgs "sensor_msgs")

;; load simple model for fast-boot
(require :go1 "package://unitreeeus/go1-simple.l")
(load "package://roseus_smach/src/state-machine-ros.l")

;; copied from https://github.com/jsk-ros-pkg/jsk_demos/blob/0a82540da013b8e21307354bb1c6a552185e36a2/jsk_spot_watch_dog/scripts/watch-dog.l
(load "package://unitreeeus/unitree-interface.l")

(defun start-func (args)
  (let ()
    (ros::ros-info "go1-initialized")
    (go1-init)
    (set-alist 'description "Start launching" args)
    :started))

(defun end-func (args)
  (let* (image (one-shot-subscribe "/image_publisher/output/compressed"
                 sensor_msgs::CompressedImage
                 timeout=10)) ;; currently it does not work
    (send *ri* :play-sound
          (pathname (ros::get-param "~bark_sound" "/opt/jsk/User/src/jsk_robot/jsk_unitree_robot/jsk_unitree_startup/autostart/bark.wav")))
    (ros::ros-info "send :play-sound, wait for 2 sec..")
    (set-alist 'description "Wakeup!" args)
    (when image
      (set-alist 'image (remove #\newline (base64encode (send image :serialize))) args))
    :finished))

(defun wakeup-sm ()
  (let (sm)
    (setq sm
          (make-state-machine
           '((:start :stated :end)
             (:end :finished :goal))
           '((:start 'start-func)
             (:end 'end-func))
           '(:start)
           '(:goal)
           ))
    (send sm :arg-keys 'description)
  sm))

(exec-state-machine (wakeup-sm))
(unix::sleep 2)
(ros::ros-info "exitting...")
(sys::exit 0)
