#!/bin/bash
##############################################################################
# This script creates a new normal user to run lxde-desktop.
# The root user can't run the lxde-desktop. so we need to create a new normal user.
# User: rzpi
# Password: 1
##############################################################################

# Ensures the script is run as root user with maximum privileges.
if [ "$(id -u)" -ne 0 ]; then
	echo "Please run this script as root or using sudo."
	exit 1
fi

# Changes the ownership of critical sudo-related files to root.
chown root:root /usr/libexec/sudo/sudoers.so
chown root:root /etc/sudo.conf
chown root:root /etc/sudoers

chown root:root /etc/sudoers.d
chown root:root /etc/sudoers.d/README

chown root:root /usr/bin/sudo
chmod 4755 /usr/bin/sudo

# Remove the password for the root user
passwd -d root

# Define the new user
USERNAME="rzpi"
PASSWORD="1"

# Check if user already exists then don't create it
if id "$USERNAME" > /dev/null 2>&1; then
	echo "User '$USERNAME' already exists."
else
	# Create user and set password
	useradd -m -s /bin/bash "$USERNAME"
	echo "$USERNAME:$PASSWORD" | chpasswd

	# Disable forced password change
	passwd -x 99999 "$USERNAME"
	passwd -n 0 "$USERNAME"

	# Add user to the sudo group
	usermod -aG sudo "$USERNAME"

	# Add user to the video groups
	usermod -aG video "$USERNAME"

	# Add user to the audio group
	usermod -aG audio "$USERNAME"

	# Add user to the audio group
	usermod -aG adm "$USERNAME"

	# Check groups
	groups "$USERNAME"

	echo "User '$USERNAME' created with the password '$PASSWORD' and granted privileges successfully."
fi
