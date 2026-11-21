# Knowledge-base entries from `vl_moe_align`

Reported by agent sessions on this kernel; the numbers are the sessions' own measurements against the kernel's strongest amdclang build.

## Per-lane slots for LDS histogram atomics (collision-free ds_add)

- **Verdict:** pays
- **Applies when:** A loop does ds_add_u32 (atomicAdd on shared memory) with data-dependent addresses and few bins relative to 64 lanes, so lanes of one instruction often hit the same address; a probe with lane-distinct addresses is much faster than the real one.
- **How:** Give each bin S slots: address = base + (4*S)*bin + 4*(lane & (S-1)) via `v_lshl_add_u32 a, bin, log2(4S), vLaneBase` (vLaneBase = base + 4*(tid & (S-1)), computed once). Zero S*bins dwords before the barrier with a ds_write loop (pad the LDS by 4 KB for the overrun), merge at the read with S/2 `ds_read2_b32` + adds. Enlarge `lds` with relaunch. Sweep S: 16 was best here.
- **Measured:** vl_moe_align with prefetch: S=64 1.235x (70 KB LDS), S=32 ~1.41x, S=16 1.538x (CI 1.530-1.544, 240 pairs), S=8 ~1.37x. Probe: 8192 ds_adds cost 20 us shared, 4.5 us lane-distinct.
- **Session:** 2026-11-21 09:22

## Prefetch through idle workgroups of the same launch

- **Verdict:** pays
- **Applies when:** One workgroup (one CU) streams a large cold input serially (about 60 GB/s per CU) while other workgroups of the launch do short independent work; probe with cached loads is much faster than cold.
- **How:** In the other workgroups' path add one `global_load_dwordx4` per thread of the input at the thread's own global index, masked to in-bounds with v_cmp + s_and_saveexec, destination in never-named VGPRs, no wait; restore exec. Outputs are unchanged.
- **Measured:** vl_moe_align: 1.039x alone (CI 1.033-1.047) because a second bound hid it; probe without ds_adds 42.6 us -> 26.6 us; part of the 1.538x state.
- **Session:** 2026-11-21 09:22

## Software-pipelined exec-mask loop (next tile's loads before the current tile's work)

- **Verdict:** parity
- **Applies when:** A masked loop issues a batch of loads, waits for all, then does work with nothing in flight.
- **How:** Preheader loads and clamps tile 0 into separate registers. Loop: save exec; advance counters; exit compare -> accumulated exit mask; exec = current & ~exit; issue next loads; exec = saved; current tile's work; exec = saved & ~exit; staged waits + first phase of next tile; s_cbranch_execnz.
- **Measured:** vl_moe_align: 1.013x alone (parity, CI 1.005-1.021); +2 % on top of prefetch + per-lane bins (1.235 -> 1.263). Probe: no change without ds_adds (42.5 against 42.6 us).
- **Session:** 2026-11-21 09:22

## Two equal bounds hide each other in probes

- **Verdict:** pays
- **Applies when:** Removing a phase (loads cached, or atomics removed) changes the time by less than 10 % although the phase is large.
- **How:** Probe with both phases removed; if that drops sharply, the bounds are parallel (max-like) and both must be fixed for a gain.
- **Measured:** vl_moe_align: 45.5 baseline; 43.3 cached loads; 42.6 no ds_add; 23.2 both.
- **Session:** 2026-11-21 09:22

## Wave-contiguous multi-KB reads with one cache line per lane

- **Verdict:** loses
- **Applies when:** Considering letting each lane read several consecutive 16-byte vectors so a wave covers 8 KB contiguously.
- **How:** Lane base = tid*128, 8 x4 loads at +16k.
- **Measured:** vl_moe_align probe 8d2300b7738b7b03: 88 us against 45.5 us.
- **Session:** 2026-11-21 09:22
