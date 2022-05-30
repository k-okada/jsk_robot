## Introduction

This project contains a set of patches and scripts to compile and run ROS 1 onboard a Go1 robot, without the need of a tethered computer, based on https://github.com/esteve/ros2_pepper

## Prepare cross-compiling environment

We're going to use Docker to set up a container that will compile all the tools for cross-compiling ROS and all of its dependencies. Go to https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository to install it for your Linux distribution.

1. Add your user to docker group
```
$ sudo usermod -aG docker $USER
$ newgrp
```

2. Install Qemu software
```
$ sudo apt install -y qemu-user-static
```

## ROS 1

### Build ROS 1

Create List of ROS packages to be installed
```
ssh pi@192.168.123.161 'source /opt/ros/melodic/setup.bash; rospack list' |tee 161-list.txt
ssh unitree@192.168.123.13 'source /opt/ros/melodic/setup.bash; rospack list' |tee 13-list.txt
ssh unitree@192.168.123.14 'source /opt/ros/melodic/setup.bash; rospack list' |tee 14-list.txt
ssh unitree@192.168.123.15 'source /opt/ros/melodic/setup.bash; rospack list' |tee 15-list.txt
cat 13-list.txt 14-list.txt 15-list.txt  | sort | uniq -c | sort | egrep "^.*3" | sed 's/^\s*3\s*\(\S*\)\s.*$/ros-melodic-\1/' | sed 's/_/-/g' | xargs | tee ros-packages.txt
```

Create List of Debian packages to be installed
```
ssh pi@192.168.123.161 'dpkg --get-selections' | tee 161-select.txt
ssh unitree@192.168.123.13 'dpkg --get-selections' | tee 13-select.txt
ssh unitree@192.168.123.14 'dpkg --get-selections' | tee 14-select.txt
ssh unitree@192.168.123.15 'dpkg --get-selections' | tee 15-select.txt
cat 161-list.txt 13-list.txt 14-list.txt 15-list.txt  | sort | uniq -c | sort | egrep "^.*4" | sed 's/^\s*4\s*\(\S*\)\s.*$/ros-melodic-\1/' | sed 's/_/-/g' | tee ros-packages.txt
```

Finally! Type the following, go grab a coffee and after a while you'll have an entire base ROS distro built for Go1 robot.

```
make system
```

### Development

On development phase, users are expected to develop sofoware on remote machine. All codes are expected to add in jsk_unitree_startup package.

### Deployment

You can send all development files to robot and start them on boot time.

```
make user
make install
```

### Known Issues

#### Running python3

Since `st-000-ros1.bash` set PYTHONPATH and we installed `python-futures` via pip, It breaks python3 execution.
When you run python3, you need to unset PYTHONPATH, i.e `PYTHONPATH= vcs`

#### Build time

Compile all System packages on aarch64 takes long time, It will take a whole day. You'd metter to obtain `arm64v8_System` directory from someone else.