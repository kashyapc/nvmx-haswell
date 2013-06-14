nVMX TODO
=========

Tests
-----

- Measure, kernel compile time in L2 to get some performance numbers.

- Run some workloads

    - Compile kernel, netperf, compile libguestfs (?)

- Some more tests related to libguestfs, maybe use libguestfs
   appliancs in some way.

- Test nEPT

    - MMU-heavy, e.g., running a lot of different processes (each with a
      different page-table), or doing a lot of page faults, will incur
      high overheads (thanks Nadav Har'El):

          e.g. -- Measure a "make" process in L1 and L2, compare it.

- Test APIC Virtualization (Intel "Haswell" doesn't have this, yet.)

- Efficient I/O tests -- Paravirtual IOMMU

- Suggestion from Gleb - Try KVM unit-tests in L2.  

    - Specifically `eventinj` test. Ensure to ompile it in 32bit, this
      way it does more tests.

- vCPU pinning to compare 'kernel build' times.

- Run multiple L2 guests in an L1. Also, try several L1 guests with
  more than one L2 in each one.

