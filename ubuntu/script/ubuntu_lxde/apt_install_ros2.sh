#!/bin/bash
# ------------------------------------------------------------------------------------------#
# This script installs ROS 2 Jazzy inside a chroot/rootfs environment.
# It ensures locale, ROS repository, GPG keyring setup, and ROS installation.
# ------------------------------------------------------------------------------------------#

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

chmod 777 /tmp

# 1. Update system and clean old cache
apt update
apt clean
apt autoclean
apt upgrade -y

# 2. Setup locale
apt install -y locales
locale-gen en_US en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# 3. Enable universe repo (required for some ROS dependencies)
apt install -y software-properties-common
add-apt-repository universe -y

# 4. Add ROS 2 GPG key securely (avoid apt-key)
ROS_KEYRING_PATH=/usr/share/keyrings/ros-archive-keyring.gpg
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o $ROS_KEYRING_PATH
chmod 644 $ROS_KEYRING_PATH

# 5. Add ROS 2 APT source list with signed-by option
UBUNTU_CODENAME="$(. /etc/os-release && echo $UBUNTU_CODENAME)"
ROS_LIST_FILE=/etc/apt/sources.list.d/ros2.list

echo "deb [arch=$(dpkg --print-architecture) signed-by=$ROS_KEYRING_PATH] http://packages.ros.org/ros2/ubuntu $UBUNTU_CODENAME main" \
    > $ROS_LIST_FILE

# 6. Final update and install ROS 2 base packages
apt update
apt install -y ros-dev-tools ros-jazzy-ros-base

echo "ROS 2 Jazzy installation complete!"
