#!/bin/bash
# ------------------------------------------------------------------------------------------#
# This script is intended to be run inside a chroot environment to install ROS2 packages as
# well as dependency packages and perform system updates. It first checks if the script is 
# executed as root, updates the package list, and installs various required utilities and packages.
# ------------------------------------------------------------------------------------------#

export LC_ALL=C
chmod 777 /tmp
apt update
apt clean
apt autoclean
apt upgrade -y
apt update

# Set DEBIAN_FRONTEND globally
export DEBIAN_FRONTEND=noninteractive

# 1. Setup locale
apt update && apt install locales -y
locale-gen en_US en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# 2. Enable required repositories
# Ensure that the Ubuntu Universe repository is enabled properly.
apt update && apt install software-properties-common -y
add-apt-repository universe -y

# Add the ROS 2 GPG key with apt
apt update && apt install curl -y
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add the repository to sources list
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
apt install /tmp/ros2-apt-source.deb

# Install development tools
apt update && apt install ros-dev-tools -y

# 3. Install ROS2
# INSTALL ROS2 JAZZY
apt update && apt upgrade -y
apt install ros-jazzy-ros-base -y

# Notify
echo "ROS2 installation complete!"