/* SPDX-License-Identifier: GPL-2.0 */
 
bool is_legacy_timestamp(void);
bool is_bpf_spoof_enabled(void);
bool always_warm_reboot(void);
bool msm_perf_disabled(void);
bool is_using_legacy_ir_hal(void);
#ifdef CONFIG_MACH_XIAOMI_F9S
bool uses_kernel_dimming(void);
#else
static inline bool uses_kernel_dimming(void) { return false; }
#endif
