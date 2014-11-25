;// *** DO NOT EDIT THIS FILE ***
;// -rw-r--r-- 1 steffen steffen 1122 Jun 21 10:22 kfunc_tab.s
#ifndef _JUMPTAB_H
#define _JUMPTAB_H
#include <system.h>
#define lkf_set_zpsize [lk_jumptab + 0]
#define lkf_get_moduleif [lk_jumptab + 2]
#define lkf_fopen [lk_jumptab + 4]
#define lkf_fopendir [lk_jumptab + 6]
#define lkf_fclose [lk_jumptab + 8]
#define lkf_fgetc [lk_jumptab + 10]
#define lkf_fputc [lk_jumptab + 12]
#define lkf_fcmd [lk_jumptab + 14]
#define lkf_freaddir [lk_jumptab + 16]
#define lkf_fgetdevice [lk_jumptab + 18]
#define lkf_strout [lk_jumptab + 20]
#define lkf_popen [lk_jumptab + 22]
#define lkf_ufd_open [lk_jumptab + 24]
#define lkf_fdup [lk_jumptab + 26]
#define lkf_print_error [lk_jumptab + 28]
#define lkf_suicerrout [lk_jumptab + 30]
#define lkf_suicide [lk_jumptab + 32]
#define lkf_palloc [lk_jumptab + 34]
#define lkf_free [lk_jumptab + 36]
#define lkf_force_taskswitch [lk_jumptab + 38]
#define lkf_forkto [lk_jumptab + 40]
#define lkf_getipid [lk_jumptab + 42]
#define lkf_signal [lk_jumptab + 44]
#define lkf_sendsignal [lk_jumptab + 46]
#define lkf_wait [lk_jumptab + 48]
#define lkf_sleep [lk_jumptab + 50]
#define lkf_lock [lk_jumptab + 52]
#define lkf_unlock [lk_jumptab + 54]
#define lkf_suspend [lk_jumptab + 56]
#define lkf_hook_alert [lk_jumptab + 58]
#define lkf_hook_irq [lk_jumptab + 60]
#define lkf_hook_nmi [lk_jumptab + 62]
#define lkf_panic [lk_jumptab + 64]
#define lkf_locktsw [lk_jumptab + 66]
#define lkf_unlocktsw [lk_jumptab + 68]
#define lkf_add_module [lk_jumptab + 70]
#define lkf_fix_module [lk_jumptab + 72]
#define lkf_mpalloc [lk_jumptab + 74]
#define lkf_spalloc [lk_jumptab + 76]
#define lkf_pfree [lk_jumptab + 78]
#define lkf_mun_block [lk_jumptab + 80]
#define lkf_catcherr [lk_jumptab + 82]
#define lkf_printk [lk_jumptab + 84]
#define lkf_hexout [lk_jumptab + 86]
#define lkf_disable_nmi [lk_jumptab + 88]
#define lkf_enable_nmi [lk_jumptab + 90]
#define lkf_get_bitadr [lk_jumptab + 92]
#define lkf_addtask [lk_jumptab + 94]
#define lkf_get_smbptr [lk_jumptab + 96]
#define lkf_smb_alloc [lk_jumptab + 98]
#define lkf_smb_free [lk_jumptab + 100]
#define lkf_alloc_pfd [lk_jumptab + 102]
#define lkf_io_return [lk_jumptab + 104]
#define lkf_io_return_error [lk_jumptab + 106]
#define lkf_ref_increment [lk_jumptab + 108]
#define lkf_p_insert [lk_jumptab + 110]
#define lkf_p_remove [lk_jumptab + 112]
#define lkf__raw_alloc [lk_jumptab + 114]
#define lkf_exe_reloc [lk_jumptab + 116]
#define lkf_exe_test [lk_jumptab + 118]
#define lkf_init [lk_jumptab + 120]
#define lkf_keyb_joy0 [lk_jumptab + 122]
#define lkf_keyb_joy1 [lk_jumptab + 124]
#define lkf_keyb_scan [lk_jumptab + 126]
#define lkf_keyb_stat [lk_jumptab + 128]
#define lkf_random [lk_jumptab + 130]
#define lkf_srandom [lk_jumptab + 132]
#define lkf_getenv [lk_jumptab + 134]
#define lkf_setenv [lk_jumptab + 136]
#endif
