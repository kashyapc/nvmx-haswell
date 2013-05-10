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

1. CPU Intensive tests
----------------------
- `kernbench` - A complile-type benchmark that compiles the Linux kernel
   multiple times.
   
- Compile libguestfs. 

2. I/O Intensive tests
----------------------
- Test I/O activity inside L2 guests (Thanks to RWMJ):

 For example::

    $ find / -exec md5sum {} \; > /dev/null
    $ find / -xdev -exec md5sum {} \; > /dev/null

- Run `netperf` on L1 & L2

3. Libguestfs tests in nVMX setup
---------------------------------
- On L0 & L1, run the below command. Note that the command needs to be run
  multiple times to get a hot cache::

    $ time guestfish -a /dev/null run' 

4. Live migration of a guest hypervisor
---------------------------------------
- FIXME

5. Multiple nested guests
-------------------------
- Run multiple nested guests


