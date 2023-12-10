		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
_sys_exit
	PUSH    {LR}
    BLX 	r11
	POP    {PC}
	BX LR
	
	IMPORT _timer_init
_sys_alarm
    PUSH    {LR}
    BL      _timer_init
    POP     {PC}
	BX LR
	
	IMPORT _signal_handler
_sys_signal
	LDR R11, = _signal_handler
    PUSH    {LR}
    BLX      R11
    POP     {PC}
	BX LR

	
	IMPORT _strncpy
_sys_memcpy
	LDR R11, = _strncpy
    PUSH    {LR}
    BLX     R11
    POP     {PC}
	BX LR
	
	IMPORT _kalloc
_sys_malloc
	LDR R11, = _kalloc
    PUSH    {LR}
    BLX     R11
    POP     {PC}
	BX LR
	
	IMPORT _kfree
_sys_free
    LDR R11, = _kfree
    PUSH    {LR}
    BLX     R11
    POP     {PC}
	BX LR

		EXPORT	_syscall_table_jump
_syscall_table_jump
		LDR        r11, = SYSTEMCALLTBL    ; load the starting address of SYSTEMCALLTBL
        MOV        r10, r7            ; copy the system call number into r10
        LSL        r10, #0x2        ; system call number * 4, so that for malloc, it is 4, for free, it is 8
        ;;-------------------------------------------------

        ADD R10, R10, R11
        LDR R1, [R10]
        BLX R1

        ;--------------------------------------------------
        BX        lr                ; return to SVC_Handler                 


    EXPORT	_syscall_table_init
_syscall_table_init
    LDR r0, =SYSTEMCALLTBL    
    LDR r1, =_sys_exit 
    STR r1, [r0], #4         
    LDR r1, =_sys_alarm
    STR r1, [r0], #4
    LDR r1, =_sys_signal
    STR r1, [r0], #4
    LDR r1, =_sys_malloc
    STR r1, [r0], #4
    LDR r1, =_sys_free
    STR r1, [r0], #4
    BX lr 

	END