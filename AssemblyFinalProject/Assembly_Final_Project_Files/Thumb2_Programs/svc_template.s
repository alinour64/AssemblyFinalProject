		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
sys_exit		EQU		0x0		; address 20007B00
sys_alarm		EQU		0x1		; address 20007B04
sys_signal		EQU		0x2		; address 20007B08
sys_memcpy		EQU		0x3		; address 20007B0C
sys_malloc		EQU		0x4		; address 20007B10
sys_free		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		EXTERN _sys_exit
		EXTERN _sys_alarm
		EXTERN _sys_signal
		EXTERN _sys_memcpy
		EXTERN _sys_malloc
		EXTERN _sys_free
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

		MOV     pc, lr 
		
		
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


_sys_exit
		BX      LR
		END

		
    EXPORT  _sys_alarm
_sys_alarm
    BX      LR


    EXPORT  _sys_signal
_sys_signal
    BX      LR


    EXPORT  _sys_memcpy
_sys_memcpy
    PUSH    {R4, LR}         
    MOV     R4, R2         
memcpy_loop:
    LDRB    R3, [R1], #1       
    STRB    R3, [R0], #1      
    SUBS    R4, R4, #1   
    BNE     memcpy_loop       
    POP     {R4, PC}           


    EXPORT  _sys_malloc
_sys_malloc
    BX      LR

    EXPORT  _sys_free
_sys_free
    BX      LR
