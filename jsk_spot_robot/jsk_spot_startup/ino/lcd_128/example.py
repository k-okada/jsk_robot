#!/usr/bin/env python

import rospy
import cv2
import numpy as np
import sys
from sensor_msgs.msg import CompressedImage


rospy.init_node('pub_compressed_image_example')
image = cv2.imread(sys.argv[1] if len(sys.argv) > 1 else '/usr/share/pixmaps/faces/legacy/penguin.jpg')
image = cv2.cvtColor(image,cv2.COLOR_RGB2GRAY)  # Comment out if you want to send color data
pub = rospy.Publisher('image/compressed', CompressedImage)
msg = CompressedImage()
msg.header.stamp = rospy.Time.now()
msg.format = 'jpeg'
msg.data = np.array(cv2.imencode('.jpg', image)[1]).tostring()
rospy.loginfo("Sending {}-byte data".format(len(msg.data)))

cv2.imshow('image', image)
rospy.loginfo('C-c or hit any key on images to stop publishing')

# test because wd can no send imagecompress??
from os import listdir
from os.path import isfile, join
images = [ join('/', f) for f in listdir('data') if isfile(join('data', f)) ]
images_i = 0;
msg.data = []
rate = rospy.Rate(10)
while (not rospy.is_shutdown()) and cv2.waitKey(1) < 0:
    msg.format = images[images_i%len(images)]
    images_i+=1
    pub.publish(msg)
    rate.sleep()




