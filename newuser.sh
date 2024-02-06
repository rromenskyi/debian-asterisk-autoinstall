#!/bin/bash

# Configuration
USERNAME='username'             # Replace with the username you want to add
GROUPNAME='username'           # Replace with the group name you want to add; leave blank if no new group is needed
SSH_PUBLIC_KEY='ssh-rsa '

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Create a new user
echo "Creating new user: $USERNAME"
adduser --disabled-password --gecos "" $USERNAME

# Add user to sudo group
usermod -a -G sudo $USERNAME
echo "$USERNAME added to sudo group"

# Set up public SSH key authentication
USER_HOME=$(getent passwd $USERNAME | cut -d: -f6)  # Get the home directory of the newly created user
mkdir -p $USER_HOME/.ssh
echo $SSH_PUBLIC_KEY > $USER_HOME/.ssh/authorized_keys
chown -R $USERNAME $USER_HOME/.ssh
chmod 700 $USER_HOME/.ssh
chmod 600 $USER_HOME/.ssh/authorized_keys
echo "Public SSH key added for $USERNAME"

echo "User $USERNAME has been successfully set up!"
