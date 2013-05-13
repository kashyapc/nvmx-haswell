======================================
Nested Virtualization with Intel (VMX)
======================================

Table of Contents
=================

::

  0] Terminology

  1] Test bed details
    1.1] L0 (host hypervisor)
    1.2] L1 (guest hypervisor)
    1.3] L2 (nested guest)

  2] L0 (host hypervisor) setup
    2.1] Install latest Fedora Kernel
    2.2] Setup KVM based Virtualization
    2.3] Enabled Nesting on L0
    2.4] Ensure Shadow VMCS is enabled on L0
    2.5] Configure bridging on L0
    
  3] L1 (guest hypervisor) setup
    3.1] Create the L1 guest
    3.2] Expose virt extensions in guest hypervisor
    3.3] QEMU command-line of L1

  4] L2 (nested guest) setup
    4.1] Create the L2 guest
    4.2] QEMU command-line of L2


0] Terminlogy
=============

- L0 -- Host hypervisor (physical host)
- L1 -- Guest hypervisor (regular guest)
- L2 -- Nested Guest (nested guest)

1] Test bed details
===================

1.1] L0 (host hypervisor)
-------------------------
- Intel Haswell, i5-4670T CPU @ 2.30GHz
- 8GB pMEM, 4 pCPU, 500GB disk
- Version:
    - Fedora 19 (minimal, @core)
    - kernel-3.10.0-0.rc0.git23.1.fc20.x86_64
    - qemu-kvm-1.4.1-1.fc19.x86_64
    - libvirt-daemon-kvm-1.0.5-2.fc19.x86_64
    - libguestfs-1.21.35-1.fc19.x86_64
- SELinux Enforcing

1.2] L1 (guest hypervisor)
--------------------------
- 150G qcow2 image (preallocated metadata w/ qemu-img; fallocate'd the
  entire disk)
- Caching attribute: `cache=none`
- Same Version details as info as L0
- 5G vMEM
- 4 vCPU

1.3] L2 (nested guest)
----------------------
- 150G qcow2 image (preallocated metadata w/ qemu-img; fallocate'd the
  entire disk)
- Caching attribute: `cache=none`
- F18
- 2G vMEM
- 2 vCPU

2] L0 (host hypervisor) setup
=============================

2.1] Install latest Fedora Kernel
---------------------------------

On the physical host (L0), install the development tools to get `koji`
cli, & then install latest the latest kernel::
    
    # Install RPM Development Tools to get koji pkgs 
    $ yum groupinstall "RPM Development Tools"

    # Find the latest kernel (which has shadow VMCS support & nVMX
    improvements - From upstream KVM git tag 3.10.1)
    $ koji latest-pkg rawhide kernel

    # Download the build from o/p of the above commanda
    $ koji download-build --arch=x86_64 kernel-3.10.0-0.rc0.git23.1.fc20

    # Install it
    $ yum localinstall *.rpm


2.2] Setup KVM based Virtualization
-----------------------------------

Install kvm/libvirt/libguestfs packages (minimal set)::

    # Install libvirt daemon for kvm, & networking pkgs
    $ yum install libvirt-daemon-kvm libvirt-daemon-config-network \
      libvirt-daemon-config-nwfilter bridge-utils netcf -y

    # Install cli tools to create virtual machines
    $ yum install python-virtinst -y

    # Install libguestfs library & its  utilities
    $ yum install libguestfs libguestfs-tools libguestfs-tools-c -y

Some more info about the host hypervisor::

    # Get basic info about L0
    $ virsh nodeinfo

    # Version details, L0
    $ uname -r ; rpm -q qemu-kvm libvirt-daemon-kvm libguestfs
    3.10.0-0.rc0.git23.1.fc20.x86_64
    qemu-kvm-1.4.1-1.fc19.x86_64
    libvirt-daemon-kvm-1.0.5-2.fc19.x86_64
    libguestfs-1.21.35-1.fc19.x86_64
 

2.3 Enabled Nesting on L0
-------------------------

Enable "nesting" on the physical host::

    # Firstl, list modules & ensure kvm modules are enabled
    $ lsmod | grep -i kvm
    kvm_intel             133627  0 
    kvm                   435079  1 kvm_intel

    # Show information kvm_intel parameter:
    $ modinfo kvm_intel | grep -i nested
    parm:           nested:bool

    # Unload, temporarily, the kvm_intel module
    $ modprobe -r kvm_intel

    # Modify the "nested" parameter for the kvm_intel kernel module, &
    reflects the value here -- /sys/module/kvm_intel/parameters/nested 
    $ modprobe kvm_intel nested=Yes

To make the above value persistent across reboots. To make it persistent, add
"options kvm-intel nested=y" to `/etc/modprobe.d/dist.conf`, & reboot the host.


2.4] Ensure Shadow VMCS is enabled on L0
----------------------------------------

.. FIXME This section requies more verbose info.

Get the MSR tools package::

    $ yum install msr-tools -y

Read information `Table 35-3`,  MSRs in Procesors Based on Intel Core
Microarchitecture, `Volume 3C of the SDM
<http://download.intel.com/products/processor/manual/325384.pdf>`__

Run the below commands::

    # Read msr value
    $ rdmsr 0x48B
    7cff00000000

    # Check Shadow VMCS is enabled:
    $ rdmsr 0x00000485
    300481e5

Next, fetch values for `nested`, `enable_shadow_vmcs`, `enable_apicv`, `ept`
features on L0 KVM kernel module parameters::

    # nested
    $ cat /sys/module/kvm_intel/parameters/nested 
    Y

    # shadow VMCS
    $ cat /sys/module/kvm_intel/parameters/enable_shadow_vmcs 
    Y

    # APIC Virtualization
    $ cat /sys/module/kvm_intel/parameters/enable_apicv 
    N

    # EPT
    $ cat /sys/module/kvm_intel/parameters/ept
    Y
  
2.5] Configure bridging on L0
-----------------------------

Please perform the below operations from a serial console/or direct
physical access to the machine:

    http://kashyapc.fedorapeople.org/virt/configuring-bridging-f19+.txt


3] L1 (guest hypervisor) setup
==============================

3.1] Create the L1 guest, get version detail
--------------------------------------------

Create a minimal Fedora guest by running virt-install::

    $ ./create-regular-guest.bash

Script used to create the above guest is located in here --
`tests/scripts/create-regular-guest.bash`


Now, update the Kernel, qemu-kvm, libguestfs packages to the same
version as host::
    
    $ virsh console regular-guest
    $ yum install libvirt-daemon-kvm libvirt-daemon-config-network \
      libvirt-daemon-config-nwfilter bridge-utils netcf -y


Ensure to have the same kernel, libvirt, qemu versions as L0, for consistency's
sake::

    # Version details, L0
    $ uname -r ; rpm -q qemu-kvm libvirt-daemon-kvm libguestfs
    3.10.0-0.rc0.git23.1.fc20.x86_64
    qemu-kvm-1.4.1-1.fc19.x86_64
    libvirt-daemon-kvm-1.0.5-2.fc19.x86_64
    libguestfs-1.21.35-1.fc19.x86_64
    $ 

On host hypervisor (L0), ensure `cache=’none’` is in the disk attribute of the
guest hypervisor’s (L1) xml file::

    $ virsh dumpxml regular-guest | grep -i none
      <driver name='qemu' type='qcow2' cache='none'/>

3.2] Expose virt extensions in guest hypervisor
-----------------------------------------------

First, on L0, check the CPU capabilities. The below is for info purposes::

    $ virsh  capabilities | virsh cpu-baseline /dev/stdin 
    <cpu mode='custom' match='exact'>
    <model fallback='allow'>Haswell</model>
    <vendor>Intel</vendor>
    <feature policy='require' name='abm'/>
    <feature policy='require' name='pdpe1gb'/>
    <feature policy='require' name='rdrand'/>
    <feature policy='require' name='f16c'/>
    <feature policy='require' name='osxsave'/>
    <feature policy='require' name='pdcm'/>
    <feature policy='require' name='xtpr'/>
    <feature policy='require' name='tm2'/>
    <feature policy='require' name='est'/>
    <feature policy='require' name='smx'/>
    <feature policy='require' name='vmx'/>
    <feature policy='require' name='ds_cpl'/>
    <feature policy='require' name='monitor'/>
    <feature policy='require' name='dtes64'/>
    <feature policy='require' name='pbe'/>
    <feature policy='require' name='tm'/>
    <feature policy='require' name='ht'/>
    <feature policy='require' name='ss'/>
    <feature policy='require' name='acpi'/>
    <feature policy='require' name='ds'/>
    <feature policy='require' name='vme'/>
    </cpu>
    $

Edit the guest hypervisor's XML, and add the below fragment to guest
hypervisor's libvirt XML to expose VMX capabilities::

    $ virsh edit regular-guest

    ---
    <cpu match='exact'>
    <model>Haswell</model>
    <feature policy='require' name='vmx'/>
    </cpu>
    ---

Optionally, also add the below fragment which tells QEMU to copy host
CPU to guest CPU ::

    <cpu mode='host-passthrough'/>


Once, edited, start L1 (regular guest)::

    $ virsh start regular-guest
    $ virsh dumpxml regular-guest | grep -i "Haswell" -A2 -B1
    <cpu mode='custom' match='exact'>
      <model fallback='allow'>Haswell</model>
      <feature policy='require' name='vmx'/>
    </cpu>

3.3] QEMU command-line of L1
----------------------------

::

    $ ps -ef | grep -i qemu
    qemu      4962     1 21 15:41 ?        00:00:41 /usr/bin/qemu-system-x86_64 -machine accel=kvm -name regular-guest -S -machine pc-i440fx-1.4,accel=kvm,usb=off -cpu Haswell,+vmx -m 6144 -smp 4,sockets=4,cores=1,threads=1 -uuid 4ed9ac0b-7f72-dfcf-68b3-e6fe2ac588b2 -nographic -no-user-config -nodefaults -chardev socket,id=charmonitor,path=/var/lib/libvirt/qemu/regular-guest.monitor,server,nowait -mon chardev=charmonitor,id=monitor,mode=control -rtc base=utc -no-shutdown -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -drive file=/home/test/vmimages/regular-guest.qcow2,if=none,id=drive-virtio-disk0,format=qcow2,cache=none -device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x4,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 -netdev tap,fd=23,id=hostnet0,vhost=on,vhostfd=24 -device virtio-net-pci,netdev=hostnet0,id=net0,mac=52:54:00:80:c1:34,bus=pci.0,addr=0x3 -chardev pty,id=charserial0 -device isa-serial,chardev=charserial0,id=serial0 -device usb-tablet,id=input0 -device virtio-balloon-pci,id=balloon0,bus=pci.0,addr=0x5
   
Log into guest hypervisor, and esure, the KVM character device is exposed::

    # Start the regular guest
    $ virsh console regular-guest

    # Check for the KVM character device file
    $ file /dev/kvm 
    /dev/kvm: character special


4] L2 (nested guest) setup
==========================

4.1] Create the L2 guest 
------------------------
Create the L2 guest (Config info in section "Test bed details"::

    $ ./create-nested-guest.bash

Script used to create L2 -- `tests/scripts/create-nested-guest.bash`


4.2] QEMU command-line of L2
----------------------------

::

    $ qemu      2042     1  0 May09 ?        00:05:03 /usr/bin/qemu-system-x86_64 -machine accel=kvm -name nested-guest -S -machine pc-i440fx-1.4,accel=kvm,usb=off -m 2048 -smp 2,sockets=2,cores=1,threads=1 -uuid 02ea8988-1054-b08b-bafe-cfbe9659976c -nographic -no-user-config -nodefaults -chardev socket,id=charmonitor,path=/var/lib/libvirt/qemu/nested-guest.monitor,server,nowait -mon chardev=charmonitor,id=monitor,mode=control -rtc base=utc -no-shutdown -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -drive file=/home/test/vmimages/nested-guest.qcow2,if=none,id=drive-virtio-disk0,format=qcow2,cache=none -device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x4,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 -netdev tap,fd=23,id=hostnet0,vhost=on,vhostfd=24 -device virtio-net-pci,netdev=hostnet0,id=net0,mac=52:54:00:65:c4:e6,bus=pci.0,addr=0x3 -chardev pty,id=charserial0 -device isa-serial,chardev=charserial0,id=serial0 -device usb-tablet,id=input0 -device virtio-balloon-pci,id=balloon0,bus=pci.0,addr=0x5

