#!/bin/bash
# 
# Copyright (C) 2012 Red Hat Inc.
# Author <kashyap.cv@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

#Let's create a minimal kickstart file with serial console enabled
#NOTE for F16 serial console login w/o any line-breaks, disable plymouth service and reboot the vm -- $ ln -s /dev/null /etc/systemd/system/plymouth-start.service

cat << EOF > fed.ks
install
text
reboot
lang en_US.UTF-8
keyboard us
network --bootproto dhcp
rootpw testpwd
firewall --enabled --ssh
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH serial text"
zerombr
clearpart --all --initlabel
autopart

%packages
@core
%end
EOF


#Disk Image location
diskimage=/home/test/vmimages/nested-guest.qcow2

#Create the qcow2 disk image with preallocation and 'facllocate'(which pre-allocates all the blocks to a file) it for max. performance
echo "Creating qcow2 disk image.."
qemu-img create -f qcow2 -o preallocation=metadata $diskimage 50G
fallocate -l `ls -al $diskimage | awk '{print $5}'` $diskimage
echo `ls -lash $diskimage`


#Create the nested-guest
virt-install --connect=qemu:///system \
    --network=bridge:virbr0 \
    --initrd-inject=./fed.ks \
    --extra-args="ks=file:/fed.ks console=tty0 console=ttyS0,115200 serial rd_NO_PLYMOUTH" \
    --name=nested-guest \
    --disk path=$diskimage,format=qcow2,cache=none \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --os-type linux \
    --os-variant fedora18 \
    --cpuset auto \
    --hvm \
    --location=http://download.fedoraproject.org/pub/fedora/linux/releases/18/Fedora/x86_64/os  \
    --nographics 

