		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
	EXPORT _ralloc
_ralloc
    PUSH {lr}
	
	;R3 = Int Entire
	SUB R9, R2, R1
	LDR R10, =MCB_ENT_SZ
	ADD R3, R9, R10
	;R4 = half
	ASR R4, R3, #1
	;R5 = midpoint
	ADD R5, R1, R4
	;R6 = heap_addr
	MOV R6, #0
	;R7 = act_entire_size
	LSL R7, R3, #4
	;R8 = act_half_size
	LSL R8, R4, #4
	

    CMP r0, r8
    BGT _ralloc_occupy
	
	
	; ----------------
	PUSH {r0-r5, r7-r12}  	; snapshot 
	; change my param
	LDR R9, =MCB_ENT_SZ
	SUB R2, R5, R9  
    BL _ralloc         		; go to recursion
	POP {r0-r5, r7-r12}   	; bring back based on snapshot
	;--------------------
	CMP R6, #0
	BEQ true
	
	; b
	LDR R11, [R5]
	
	;a - R10
	AND R10, R11, #0x01
	
	CMP R10, #0
	BEQ next
	
	B RETURN
	
next
	STR R8, [R5]
	B RETURN
	
true
	PUSH {r0-r5, r7-r12}  	; snapshot  
	MOV R1, R5
    BL _ralloc         		; go to recursion
	POP {r0-r5, r7-r12}
	
	B RETURN
	
_ralloc_occupy ;; DONE ELSE OF 1ST IF
	
	;b - R9
	LDR R9, [R1]
	
	;a - R10
	;AND R10, b, #0X01
	AND R10, R9, #0x01
	
	;CMP a,#0 BECAUSE IF STATEMENT
	CMP R10,#0
	BNE RETURN_NULLs
	
	;a - R10
	LDR R10, [R1]
	
	;CMP a, R7
	CMP R10, R7
	BLT RETURN_NULLs
	
	;b - R10
	ORR R10, R7, #0x01
	
	;STR b, [R1]
	STR R10, [R1]
	
	LDR R10, = MCB_TOP
	LDR R11, = HEAP_TOP
	; R6s
	SUB R6, R1, R10
	LSL R6, R6, #4
	ADD R6, R6, R11
	
	; RETURN VAL TO SAVE TO R6
	B	RETURN
	
RETURN_NULLs
	MOV R6, #0
	B RETURN
	
RETURN 
	POP {LR}
	BX LR


	EXPORT _rfree
_rfree
	PUSH{LR}
    LDR R2, = MCB_TOP

	;  short mcb_contents = *(short *)&array[ m2a( mcb_addr ) ];
	;R3 = mcb_contents
	LDR R3, [R4]
	;int mcb_offset = mcb_addr - mcb_top;
	;R4 = mcb_offset
	SUB R9, R4, R2
	;int mcb_chunk = ( mcb_contents /= 16 );
	;R5 = mcb_chunk
	LSR R3, R3, #4
	MOV R5, R3
	;  int my_size = ( mcb_contents *= 16 ); // clear the used bit
	;R6 = my_size
	LSL R3, R3, #4
	MOV R6, R3
 
    STR R3, [R4] 

	SDIV R12, R9, R5
	AND R12, R12, #1
	CMP R12, #0
	BEQ equal
	B skip
equal 
	ADD R7, R4, R5
	LDR R8, =MCB_BOT
	CMP R7, R8
	BGE.W return_null
	ADD R7, R4, R5
	;R7 = mcb_buddy
	LDR R11, [R7]
	
	AND R8, R11, #1
	CMP R8, #0
	
	LSL R11, R11, #5
	ASR R11, R11, #5
	CMP R11, R6
	
	BNE RFREE_RETURN
	
	CMP R12, #0x0
	BEQ left_free
	
	;Clear my buddy
	MOV R8, #0
	ADD R9, R4, R5
	STR R8, [R9]
	
	LSL R6, R6, #1;
	;merge my buddy
	STRH R6, [R7]
	MOV  R4, R7
	
	
		; ----------------
	PUSH {r0, r2-r12}  	; snapshot 
							; change my para
    BL _rfree         		; go to recursion
	POP {r0, r2-r12}   	; bring back based on snapshot
	;--------------------
	
	B RFREE_RETURN

	
	
skip
	SUB R7, R4, R5
	LDR R8, =MCB_TOP
	CMP R7, R8
	BLT return_null
	
	;R7 = mcb_buddy
	LDR R11, [R7]
	AND R8, R11, #1
	CMP R8, #0
	BNE RFREE_RETURN
	ASR R11, R11, #5
	LSL R11, R11, #5
	CMP R11, R6
	BNE RFREE_RETURN
	CMP R12, #0
	BEQ left_free
	
	;clear myself
	MOV R10, #0
	STR R10, [R4]
	
	LSL R6, R6, #1;
	;merge me to my buddy
	STRH R6, [R7]
	MOV  R4, R7
	
	; ----------------
    BL _rfree         		; go to recursion
	;--------------------
	B RFREE_RETURN
	
left_free
	STRH R8, [R7]
	LSL  R6, R6, #1
	STRH R6, [R4]

	; ----------------
    BL _rfree         		; go to recursion
	;--------------------

	B RFREE_RETURN

RFREE_RETURN
	POP{LR}
	BX LR


	EXPORT _kinit
_kinit
    PUSH {r4, r5, lr}       
    LDR r4, =MCB_TOP       
    LDR r5, =MAX_SIZE       
    STR r5, [r4]           

    LDR r4, =MCB_TOP
    ADD r4, r4, #4          

init_loop
    LDR r5, =MCB_BOT
    CMP r4, r5
    BGE end_init
    MOVS r6, #0x0
    STR r6, [r4]           
    ADD r4, r4, #4        
    B init_loop

end_init
    POP {r4, r5, pc}


	EXPORT _kalloc
_kalloc
    PUSH {lr}          
            

    CMP r0, #32
    BGE skip_size_adjustment 
    MOV r0, #32
	
skip_size_adjustment

    LDR r1, =MCB_TOP
    LDR r2, =MCB_BOT
              
	; ----------------
	PUSH {LR}  	; snapshot 
		; change my para
    BL _ralloc         		; go to recursion
	POP {LR}   	; bring back based on snapshot
	;--------------------
	MOV R0, R6
    POP {lr}             
	BX lr
	
	
	EXPORT _kfree
_kfree
	PUSH {LR}

	;R2 = heap_top
	LDR R2, =HEAP_TOP
	;R3 = heap_bot
	LDR R3,	=HEAP_BOT
	
	CMP     r0, r2      
    BLT     return_null

check_heap_bot
    CMP     r0, r3     
    BGT     return_null



addr_is_valid

	LDR R5, =MCB_TOP
	SUB R4, R0, R2
	LSR R4, R4, #4
	ADD R4, R4, R5
	
	; ----------------
	PUSH {r0, r2-r12}  	; snapshot 
							; change my para
    BL _rfree         		; go to recursion
	POP {r0, r2-r12}   	; bring back based on snapshot
	;--------------------
	CMP R6, #0
	BEQ return_null
	MOV R0, R6
	B KFREE_RETURN

return_null
	MOV R0, #0

KFREE_RETURN
	POP {LR}
    BX LR  



	EXPORT _heap_init
_heap_init
    PUSH {r4, r5, lr}      

    LDR r4, =HEAP_TOP       
    LDR r5, =HEAP_BOT       

init_mcb_loop
    CMP r4, r5             
    BGE end_inits           
    MOVS r0, #0         
    STRH r0, [r4]           
    ADD r4, r4, #2         
    B init_mcb_loop    

end_inits
    POP {r4, r5, pc}        


	END