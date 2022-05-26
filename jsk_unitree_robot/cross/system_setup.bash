#!/bin/bash

for script_file in $(ls /opt/jsk/System/startup_scripts|sort); do
  source /opt/jsk/System/startup_scripts/${script_file}
done
