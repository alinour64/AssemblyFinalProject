		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		; r2 = 0
		STMFD	sp!, {r1-r12,lr}
		MOV		r3, r0				; r3 = dest
		MOV		r2, #0				; r2 = 0;	
_bzero_loop							; while( ) {
		SUBS	r1, r1, #1			; 	n--;
		BMI		_bzero_return		;   if ( n < 0 ) break;	
		STRB	r2, [r0], #0x1		;	[s++] = 0;
		B		_bzero_loop			; }
_bzero_return
		MOV		r0, r3				; return dest;
		LDMFD	sp!, {r1-r12,lr}
		MOV PC, LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size
		; r3 = a copy of original dest
		; r4 = src[i]
		STMFD	sp!, {r1-r12,lr}
		MOV		r3, r0				; r3 = dest
_strncpy_loop						; while( ) {
		SUBS	r2, r2, #1			; 	size--;
		BMI		_strncpy_return		; 	if ( size < 0 ) break; 		
		LDRB	r4, [r1], #0x1		; 	r4 = [src++];
		STRB	r4, [r0], #0x1		;	[dest++] = r4;
		CMP		r4, #0				;   
		BEQ		_strncpy_return		;	if ( r4 = '\0' ) break;
		B		_strncpy_loop		; }
_strncpy_return
		MOV		r0, r3				; return dest;
		LDMFD	sp!, {r1-r12,lr}
		MOV PC, LR  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
	IMPORT _kinit
	EXPORT _malloc
_malloc
	PUSH {R1-R12, LR}       
                
    MOV R7,#3            
    SVC #0x0
	
    POP {R1-R12, LR}         

    MOV PC, LR            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT _free
_free
	PUSH {R1-R12, LR}      
                
    MOV R7,#4             
    SVC #0x0
	
    POP {R1-R12, LR}        
    MOV PC, LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
    PUSH {R1-R12, LR}         
                
    MOV R7,#1              
    SVC #0x0
	
    POP {R1-R12, LR}           
    BX LR       


			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT _signal
_signal
    PUSH {R1-R12, LR}        
                
    MOV R7,#2        
    SVC #0x0
    POP {R1-R12, LR}    
    BX LR       


 EXPORT _strlen
_strlen
	MOV r1, #0 
_strlen_loop
	LDRB r2, [r0, r1]
	CMP r2, #0 
	BEQ _strlen_return 
	ADD r1, r1, #1 
	B _strlen_loop
_strlen_return
	MOV r0, r1 
	MOV PC, LR



    EXPORT _memsets
_memsets
    STMFD sp!, {r4, lr}       ; Save registers r4 and lr
    MOV   r3, r0              ; r3 = dest (preserve original dest pointer for return)
    MOV   r4, r2              ; r4 = n (count)
    AND   r1, r1, #0xFF       ; Ensure r1 (value to set) is a byte
_memsets_loop
    CMP   r4, #0              ; Compare count with 0
    BEQ   _memsets_return      ; If count is 0, exit loop
    SUBS  r4, r4, #1          ; Decrement count
    STRB  r1, [r0], #1        ; Set byte at dest to value in r1 and increment dest
    BNE   _memsets_loop        ; Repeat loop if count is not zero
_memsets_return
    MOV   r0, r3              ; Set return value to original dest pointer
    LDMFD sp!, {r4, lr}       ; Restore registers r4 and lr
    MOV   PC, LR              ; Return from function
           





	EXPORT _toupper
_toupper
	CMP r0, #'a' 
	BLT _toupper_return 
	CMP r0, #'z' 
	BGT _toupper_return 
	SUB r0, r0, #32 
_toupper_return
	MOV PC, LR
	
	
	EXPORT _strcmp
_strcmp
	PUSH  {lr}
_strcmp_loop
	LDRB  r2, [r0], #1
	LDRB  r3, [r1], #1
	CMP   r2, r3         
	BNE   _strcmp_done  
	CMP   r2, #0        
	BNE   _strcmp_loop
	MOV   r0, #0       
	POP   {pc}
_strcmp_done
	SUBS  r0, r2, r3   
	POP   {pc}
	
	EXPORT _strcat
_strcat
	STMFD sp!, {r4, lr}
	MOV r3, r0 
_strcat_find_end
	LDRB r2, [r3], #1 
	CMP r2, #0 
	BNE _strcat_find_end
	SUB r3, r3, #1 
_strcat_append
	LDRB r2, [r1], #1
	STRB r2, [r3], #1 
	CMP r2, #0 
	BNE _strcat_append 
	MOV r0, r0 
	LDMFD sp!, {r4, lr} 
	MOV PC, LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
