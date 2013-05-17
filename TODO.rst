nVMX TODO
=========

Tests
-----

1/ Measure, kernel compile time in L2 to get some performance numbers.

2/ Run some workloads

    - Compile kernel, netperf, compile libguestfs (?)

3/ Some more tests related to libguestfs, maybe use libguestfs
   appliancs in some way.

4/ Test nEPT

    - MMU-heavy, e.g., running a lot of different processes (each with a
      different page-table), or doing a lot of page faults, will incur
      high overheads (thanks Nadav Har'El):

          e.g. -- Measure a "make" process in L1 and L2, compare it.

5/ Test APIC Virtualization (Intel "Haswell" doesn't have this, yet.)

6/ Efficient I/O tests -- Paravirtual IOMMU

7/ Suggestion from Gleb - Try KVM unit-tests in L2.  

    - Specifically `eventinj` test. Ensure to ompile it in 32bit, this
      way it does more tests.

8/ vCPU pinning to compare 'kernel build' times.
