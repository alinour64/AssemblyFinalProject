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
	POP    {LR}
	BX LR
	
	IMPORT _alarm
_sys_alarm
    PUSH    {LR}
    BL      _alarm
    POP     {PC}
	BX LR
	
	IMPORT _signal
_sys_signal
    LDR R11, = _signal
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
    LDR r1, =SYSTEMCALLTBL   
    LSL r0, r0, #2      
    ADD r0, r1, r0           
    LDR r0, [r0]             
    BX r0                     


    EXPORT	_syscall_table_init
_syscall_table_init
    LDR r0, =SYSTEMCALLTBL    
    LDR r1, =_sys_exit 
    STR r1, [r0], #4         
    LDR r1, =_sys_alarm
    STR r1, [r0], #4
    LDR r1, =_sys_signal
    STR r1, [r0], #4
    LDR r1, =_sys_memcpy
    STR r1, [r0], #4
    LDR r1, =_sys_malloc
    STR r1, [r0], #4
    LDR r1, =_sys_free
    STR r1, [r0], #4
    BX lr   