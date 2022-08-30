#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine-ros.l")

(require :base64 "lib/llib/base64.l")

(ros::roseus-add-msgs "jsk_recognition_msgs")
(ros::roseus-add-msgs "sensor_msgs")

(setq *img* nil)
(setq joy-msg nil)
(setq last-time-input-joy (ros::time))
(setq walk-end-duration 120)
(setq find-person-msg (instance jsk_recognition_msgs::PeoplePoseArray :init))
(defun find-person-cb (msg)
  (setq find-person-msg msg))

(defun joy-cb (msg)
  (setq joy-msg msg)
  (setq last-time-input-joy (send msg :header :stamp)))

(defun image-cb (msg)
  (setq *img* (copy-object msg)))

(defun start-func (args)
  (let ()
    (while (null joy-msg)
      (ros::ros-info "start  : wait lead input.")
      (ros::spin-once)
      (ros::sleep))
    (set-alist 'description "散歩を始めるよ" args)
    (when *img* (set-alist 'image (remove #\newline (base64encode (send *img* :serialize))) args))
    :started))


(defun end-func (args)
  (let ()
    (set-alist 'description "散歩を終えるよ" args)
    (when *img* (set-alist 'image (remove #\newline (base64encode (send *img* :serialize))) args))
    :finished))

(defun walk-func (args)
  (let ((last-time-seen-person 9999))
    (while (> last-time-seen-person 5)
      (when (> (send (ros::time- (ros::time-now) last-time-input-joy) :to-sec) walk-end-duration)
        (return-from walk-func :finished))
      (when (> (length (send find-person-msg :poses)) 0)
        (setq last-time-seen-person (send (ros::time- (ros::time-now) (send find-person-msg :header :stamp)) :to-sec)))
      (ros::ros-info "walk  : detect person ~A sec ago" last-time-seen-person)
      (ros::spin-once)
      (ros::sleep))
    (set-alist 'description "歩いているよ" args)
    (when *img* (set-alist 'image (remove #\newline (base64encode (send *img* :serialize))) args))
    ;; set description and goes to next state
    :find-person))

(defun find-person-func (args)
  (let ()
    (set-alist 'description "散歩中に人を見つけたよ" args)
    (when *img* (set-alist 'image (remove #\newline (base64encode (send *img* :serialize))) args))
    :walk))

(defun lead-teleop-sm ()
  (let (sm)
    (setq sm
          (make-state-machine
           '((:start :started :walk)
             (:walk :find-person :find-person)
             (:walk :finished :end)
             (:find-person :walk :walk)
             (:end :finished :finish))
           '((:start 'start-func)
             (:walk 'walk-func) ;; function maps
             (:find-person 'find-person-func)
             (:end 'end-func))
           '(:start)      ;; initial
           '(:finish)       ;; goal
           ))
    (send sm :arg-keys 'description)
    sm))

(ros::roseus "lead-teleop-smach")
(ros::rate 1)
(setq last-time-input-joy (ros::time-now))
(ros::subscribe "/people_pose" jsk_recognition_msgs::PeoplePoseArray #'find-person-cb)
(ros::subscribe "/joy_head/joy_raw" sensor_msgs::Joy #'joy-cb)
(ros::subscribe "/front_camera/output/compressed" sensor_msgs::CompressedImage #'image-cb)
(do-until-key
  ;; state machine
  (exec-state-machine (lead-teleop-sm)
                      `((description . ,(format nil "~A" "Unitree　お散歩しました"))
                        (image . "")))
  (setq joy-msg nil)
  (setq last-time-input-joy (ros::time)))
(ros::exit)
