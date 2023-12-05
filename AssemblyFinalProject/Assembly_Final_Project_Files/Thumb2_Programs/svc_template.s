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
; System Call Table Initialization
_sys_exit
    BX      lr
    END
		EXPORT	_syscall_table_init
_syscall_table_init
    LDR     R0, =SYSTEMCALLTBL     
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
    STR     R1, [R0]

    MOV     pc, lr                ; Return from the function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
    LDR     R1, =SYSTEMCALLTBL    
    LDR     R2, [R7]              
    LSL     R2, R2, #2           
    ADD     R1, R1, R2             
    LDR     R1, [R1]             
    BLX     R1                     

    MOV     pc, lr                

        END