#!/bin/bash


# ros1_deendenceis
export PKG_CONFIG_PATH="/opt/jsk/System/ros1_dependencies/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="/opt/jsk/System/ros1_dependencies/lib:${LD_LIBRARY_PATH}"
export PYTHONPATH="/opt/jsk/System/ros1_dependencies/lib/python2.7/site-packages:${PYTHONPATH}"

# Python
export LD_LIBRARY_PATH="/opt/jsk/System/Python/lib:${LD_LIBRARY_PATH}"
export PYTHONPATH="/opt/jsk/System/Python/lib/python2.7/site-packages:${PYTHONPATH}"
export PATH="/opt/jsk/System/Python/bin:${PATH}"

source /opt/jsk/System/ros1_inst/setup.bash
