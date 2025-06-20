#!/bin/bash
##############################################################################
# Install latest Mesa drivers on Ubuntu
# Install packages to run ubuntu-gnome-desktop on ubuntu.
##############################################################################

apt update
apt upgrade -y

# Install Ubuntu desktop
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f ubuntu-minial-desktop

# Remove cloud-init
apt purge -y cloud-init
