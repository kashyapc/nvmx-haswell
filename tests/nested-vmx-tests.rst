nVMX Tests
==========
This write up outlines the test setup and details to benchmark nested
virtualization test with Intel.


Terminology
-----------
L0 - Host Hypervisor
L1 - Guest Hypervisor
L2 - Nested Guest


Test environment
----------------
Test environment details:

- L0, L1, L2  -- All running minimal (@core only) RHEL7 / Fedora with
  latest kernel.
    - L0 -- 4 pCPUs, 20GB RAM
    - L1 -- 4 vCPUs, 4GB RAM 
    - L2 -- 2 vCPUs, 2GB RAM

- Networking:
    - L1 uses L0's standard linux bridge device - br0
    - L2 uses Libvirt's default bridge - virbr0

- Storage:
    - L1 uses a RAW disk or QCOW2 (with preallocation=metadata,
      & fallocate).
    - L2 uses a qcow2/v3 disk.

    - With cache=none

- Ensure serial console is enabled on L1 & L2 kernel command line
    - "console=tty0 console=ttyS0,115200"


Tests
=====
Once the nested guest (L2) is up and running, the below tests can be run
to demonstrate the current state of it:

0. KVM Unit Tests
-----------------
- Run upstream KVM unit-tests inside L2 guest.

1. CPU Intensive tests
----------------------
- A complile-type benchmark that compiles the Linux kernel
  multiple times.

- Run multiple nested guests.

    - Build upstream kernel (w/ & w/o nesting, VMCS Shadowing) on
      L2 (to measure 'VMCS Shadowing' performance numbers). *NOTE*:
      Use Kernels w/ debug turned off.
        - http://thread.gmane.org/gmane.comp.emulators.kvm.devel/109746
        - http://thread.gmane.org/gmane.comp.emulators.kvm.devel/109668
        - Also caputure kvm_stat results

    - Build upstream kernel on L1. Compare w/ L2.
    - Some performance comparison when enable/disable VMCS shadowing

2. EPT (MMU combinations)
-------------------------

- Shadow (page tables) on Shadow  -- disable EPT in L0
   - software-only

- Shadow on EPT -- EPT enabled in L0 but disabled in L1

- Shadow on nEPT -- EPT enabled in L0 and L1

   
3. I/O Intensive tests
----------------------
- Test I/O activity inside L2 guests (Thanks to RWMJ). This is a
  system test, but still might be useful:

 For example::

    $ find / -exec sha256sum {} \; > /dev/null
    $ find / -xdev -exec sha256sum {} \; > /dev/null

- Run `netperf` on L1 & L2

4. Libguestfs tests in nVMX setup
---------------------------------
- On L0 & L1, run the below command. Note that the command needs to be run
  multiple times to get a hot cache::

    $ for i in {1..10}; do time guestfish \
      -a /dev/null run; done | tee \
      guestfish-timings-L1.txt

5. Live migration of a guest hypervisor
---------------------------------------
- FIXME

6. Multiple nested guests
-------------------------
- Run multiple nested guests to run stability


7. System tests
---------------


