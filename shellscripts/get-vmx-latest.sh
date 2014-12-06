#!/bin/bash
# Settings
WORKING_PATH=/srv/vmx/latest
BACKUP_CONFIG=/root/backup/config.json.vmx

# Move to the working directory
cd $WORKING_PATH
# - remove all existing files and directories
rm -r $WORKING_PATH/*
#
# Get the latest archives
#
# vmxAppBuilder, vmxMiddle, vmxServer
echo "Decompressing.."
echo "vmxAppBuilder"
wget -A.gz https://files.vision.ai/vmx/vmxAppBuilder/vmxAppBuilder.latest.tar.gz
echo "VMXmiddle_Linux"
wget -A.gz https://files.vision.ai/vmx/VMXmiddle/Linux/VMXmiddle_Linux.latest.tar.gz
echo "VMXserver_Linux"
wget -A.gz https://files.vision.ai/vmx/VMXserver/Linux/VMXserver_Linux.latest.tar.gz
#
# Decompress archives
tar xvf vmxAppBuilder.latest.tar.gz
tar xvf VMXmiddle_Linux.latest.tar.gz
tar xvf VMXserver_Linux.latest.tar.gz
#
# Update license from backup
# - get license key from backup
EXISTING_USER=$(cat $BACKUP_CONFIG | sed '/user/!d; s/"//g; s/ //g; s/,//; s/user://')
EXISTING_LICENSE=$(cat $BACKUP_CONFIG | sed '/license/!d; s/"//g; s/ //g; s/,//; s/license://')
echo "Pulling info from config backup"
# - backup the new version of the config from the latest release;
# - update the new config with the existing user and license information before moving to the docker container
echo "Updating new config file"
cp $WORKING_PATH/build/config.json $WORKING_PATH/build/config.json.bak
# - update license
sed "s/\"license\".*:.*\".*\"/\"license\": \"$EXISTING_LICENSE\"/" $WORKING_PATH/build/config.json.bak > $WORKING_PATH/build/config.json
# - update user
cp $WORKING_PATH/build/config.json $WORKING_PATH/build/config.json.step-with-license
sed "s/\"user\".*:.*\".*\"/\"user\": \"$EXISTING_USER\"/" $WORKING_PATH/build/config.json.step-with-license > $WORKING_PATH/build/config.json
rm $WORKING_PATH/build/config.json.step-with-license
echo
echo 'Update on new config file compelte'
cat $WORKING_PATH/build/config.json
#
# Check if docker is running
if [ $(ps aux | grep -v grep | grep docker | wc -l) -ge 1 ]; then
    # docker appears to be running, get the container paths to copy latest files
    VMX_CONTAINER_ID=$(docker ps | awk '/visionai\/vmx-env/{print $1}')
    mkdir tmp
    docker inspect $VMX_CONTAINER_ID | awk 'length($0)>80{print}' > tmp/vmx_container_dirs
    VFS_VMX_MATLAB="$(awk '/root\/MATLAB/{print $NF}' tmp/vmx_container_dir | sed 's/"//g; s/,//g')"
    VFS_VMX_BUILD="$(awk '/vmx\/build/{print $NF}' tmp/vmx_container_dir | sed 's/"//g; s/,//g')"
    VFS_VMX_DATA="$(awk '/vmx\/data/{print $NF}' tmp/vmx_container_dir | sed 's/"//g; s/,//g')"
    VFS_VMX_MIDDLE="$(awk '/vmx\/middle/{print $NF}' tmp/vmx_container_dir | sed 's/"//g; s/,//g')"
    VFS_VMX_STATIC="$(awk '/vmx\/middle\/static/{print $NF}' tmp/vmx_container_dir | sed 's/"//g; s/,//g')"
    VFS_VMX_MODELS="$(awk '/vmx\/models/{print $NF}' tmp/vmx_container_dir | sed 's/"//g; s/,//g')"
    VFS_VMX_SESSIONS="$(awk '/vmx\/sessions/{print $NF}' tmp/vmx_container_dir | sed 's/"//g; s/,//g')"
    rm -r tmp
else
    # docker does not appear to be running
    echo "docker is not running"
fi