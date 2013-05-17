NOTES
=====

Resources
---------
* Upstream SPEC
    - http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/virtual/kvm/nested-vmx.txt

* Upstream nVMX meta bug
    - https://bugzilla.kernel.org/show_bug.cgi?id=53601

* Related Notes
    - http://kashyapc.wordpress.com/tag/nested-virtualization/
    - https://github.com/kashyapc/nested-virt-notes-intel-f18

* nVMX shadow VMCS support 
    - v5 - http://comments.gmane.org/gmane.comp.emulators.kvm.devel/108401
    - v1 - http://comments.gmane.org/gmane.comp.emulators.kvm.devel/106114


Use Cases
---------
Below are some use cases for nested virt (some of them are collated from
upstream, KVM discussions).

    * OpenStack can seriously take advantage of good nested virt performance:

        - Very useful for OpenStack in a single node (VM) set ups can be tested
          more meaningfully.

        - Where: L0 -- Physical host; L1 -- Guest hypervisor; L2 -- Nested guest

    * A "cloud user" gets a beefy guest hypervisor & can cheerfully run/manage
      multiple guests for developing or testing w/o the hassle and intervention of
      the cloud provider.

    * Enable live migration of entire hypervisors with their guests - for
      load balancing, disaster recovery, and so on.

    * Make it easier to test, demonstrate, benchmark and debug hypervisors,
      and also entire virtualization setups. An entire virtualization setup
      (hypervisor and all its guests) could be run as one virtual machine,
      allowing testing many such setups on one physical machine.

    * Hosting one of the new breed of operating systems which have a hypervisor
      as part of them. Windows 7 with XP mode is one example. Linux with KVM
      is another.

    * Platforms with embedded hypervisors in firmware need nested virt to
      run any workload - which can itself be a hypervisor with guests.

    * Honeypots and protection against hypervisor-level rootkits.

Limitations from Turtles project
--------------------------------
(The below notes are as of 2-FEB-2013, after discussion with Nadav)

1. Nested EPT, which we had for the research paper, is still not in mainline
   KVM (see https://bugzilla.kernel.org/show_bug.cgi?id=53611). This
   means that benchmarks which are MMU-heavy, e.g., running a lot of
   different processes (each with a different page-table), or doing a
   lot of page faults, will incur high overheads. For example I measured
   a "make" process taking 87 seconds in L2, compared to 25 seconds in
   L1. With the patches in the above link, the time is down to 29
   seconds.
      - [knoel pointed, now this is upstream] --
        http://www.spinics.net/lists/kvm/msg87634.html

2. The best measurements in the paper used exit-less VMREAD and VMWRITE,
   which was emulated in the paper and only now processors are beginning
   to add this feature (called "vmcs shadowing), but it's not yet in KVM -
   and not yet in your processor, anyway.

3. For efficient I/O, we used in a the paper a few hacks (paravirtual
   IOMMU, polling in the guest). Without them (or less-hacky
   alternatives, on which we are working), your I/O performance will not
   be as great as in the paper.

