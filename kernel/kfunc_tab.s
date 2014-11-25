	.global	kfunc_tab

kfunc_tab:
	.word set_zpsize
	.word get_moduleif
	.word fopen
	.word fopendir
	.word fclose
	.word fgetc
	.word fputc
	.word fcmd
	.word freaddir
	.word fgetdevice
	.word strout
	.word popen
	.word ufd_open
	.word fdup
	.word print_error
	.word suicerrout
	.word suicide
	.word palloc
	.word free
	.word force_taskswitch
	.word forkto
	.word getipid
	.word signal
	.word sendsignal
	.word wait
	.word sleep
	.word lock
	.word unlock
	.word suspend
	.word hook_alert
	.word hook_irq
	.word hook_nmi
	.word panic
	.word locktsw
	.word unlocktsw
	.word add_module
	.word fix_module
	.word mpalloc
	.word spalloc
	.word pfree
	.word mun_block
	.word catcherr
	.word printk
	.word hexout
	.word disable_nmi
	.word enable_nmi
	.word get_bitadr
	.word addtask
	.word get_smbptr
	.word smb_alloc
	.word smb_free
	.word alloc_pfd
	.word io_return
	.word io_return_error
	.word ref_increment
	.word p_insert
	.word p_remove
	.word _raw_alloc
	.word exe_reloc
	.word exe_test
	.word init
	.word keyb_joy0
	.word keyb_joy1
	.word keyb_scan
	.word keyb_stat
	.word random
	.word srandom
	.word getenv
	.word setenv