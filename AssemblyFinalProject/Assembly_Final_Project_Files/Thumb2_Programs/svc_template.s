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


    LDR     R0, =0x20007B00     
    LDR     R1, =_sys_exit
    STR     R1, [R0], #4      
    LDR     R1, =_sys_alarm
    STR     R1, [R0], #4
    LDR     R1, =_sys_signal
    STR     R1, [R0], #4
    LDR     R1, =_sys_memcpy
    STR     R1, [R0], #4
    LDR     R1, =_sys_malloc
    STR     R1, [R0], #4
    LDR     R1, =_sys_free
    STR     R1, [R0], #4


_sys_exit
    BX      LR
	
	EXTERN _alarm
_sys_alarm
    PUSH    {LR}
    BL      _alarm
    POP     {PC}

	EXTERN _signal
_sys_signal
    MOV     R4, R0
    MOV     R5, R1
    BL      _signal
    POP     {R4-R7, PC}

_sys_memcpy
    PUSH    {R4, LR}
    MOV     R4, R2
memcpy_loop
    LDRB    R3, [R1], #1
    STRB    R3, [R0], #1
    SUBS    R4, R4, #1
    BNE     memcpy_loop
    POP     {R4, PC}

	EXTERN _malloc
_sys_malloc
    PUSH    {LR}
    MOV     R0, R0
    BL      _malloc
    POP     {PC}

	EXTERN _free
_sys_free
    PUSH    {LR}
    MOV     R0, R0
    BL      _free
    POP     {PC}

    EXPORT	_syscall_table_jump
_syscall_table_jump
    LDR     R1, =0x20007B00
    LDR     R2, [R7]
    LSL     R2, R2, #2
    ADD     R1, R1, R2
    LDR     R1, [R1]
    BLX     R1
    MOV     pc, lr

    EXPORT	_syscall_table_init
_syscall_table_init
    LDR     R0, =0x20007B00     
    LDR     R1, =_sys_exit
    STR     R1, [R0], #4      
    LDR     R1, =_sys_alarm
    STR     R1, [R0], #4
    LDR     R1, =_sys_signal
    STR     R1, [R0], #4
    LDR     R1, =_sys_memcpy
    STR     R1, [R0], #4
    LDR     R1, =_sys_malloc
    STR     R1, [R0], #4
    LDR     R1, =_sys_free
    STR     R1, [R0], #4
    BX      LR

    END