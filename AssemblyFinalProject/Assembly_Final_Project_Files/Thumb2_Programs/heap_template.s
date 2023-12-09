		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x200057FF
HEAP_BOT	EQU		0x20005000
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

	;;;;;
	
	

    CMP r0, r8
    BGT _ralloc_occupy
	
	
	; ----------------
	PUSH {r0-r5, r7-r12}  	; snapshot 
	; change my para
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
	AND R10, R11, #1
	
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
	AND R10, R9, #0X01
	
	;CMP a,#0 BECAUSE IF STATEMENT
	CMP R10,#0
	BNE RETURN_NULL
	
	;a - R10
	LDR R10, [R1]
	
	;CMP a, R7
	CMP R10, R7
	BLT RETURN_NULL
	
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
	
RETURN_NULL
	MOV R6, #0
	B RETURN
	
RETURN 
	POP {LR}
	BX LR


	EXPORT _rfree
_rfree
    PUSH {r4-r7, lr}

    MOV r4, r0
    LDR r2, =MCB_TOP        
    ADD r1, r4, r2         
    LDR r5, [r1]                

    SUB r6, r4, r2        
    LSRS r5, r5, #4
    LSLS r5, r5, #4
    STRH r5, [r1]           

    LSRS r7, r6, r5
    ANDS r7, r7, #1
    CMP r7, #0
    BEQ _rfree_left
    B _rfree_right


_rfree_left
    ADD r7, r4, r5
    LDR r1, =MCB_BOT        
    CMP r7, r1
    BGE _rfree_exit_zero
    ADD r1, r7, r3
    LDRH r7, [r1]       
    ANDS r0, r7, #1
    CMP r0, #0
    BNE _rfree_exit            
    LSRS r7, r7, #5
    LSLS r7, r7, #5            
    CMP r7, r5
    BNE _rfree_exit            
    MOVS r7, #0
    ADD r1, r4, r5
    ADD r1, r1, r3
    STRH r7, [r1]    
    LSLS r5, r5, #1            
    ADD r1, r4, r3
    STRH r5, [r1]       
    MOV r0, r4
    BL _rfree                 
    B _rfree_exit
	
	
_rfree_right
    SUB r7, r4, r5
    CMP r7, r2             
    BLT _rfree_exit_zero
    ADD r1, r7, r3
    LDRH r7, [r1]       
    ANDS r0, r7, #1
    CMP r0, #0
    BNE _rfree_exit           
    LSRS r7, r7, #5
    LSLS r7, r7, #5          
    CMP r7, r5
    BNE _rfree_exit
    MOVS r7, #0
    ADD r1, r4, r3
    STRH r7, [r1]     
    LSLS r5, r5, #1            
    SUB r1, r4, r5
    ADD r1, r1, r3
    STRH r5, [r1]      
    SUB r0, r4, r5
    BL _rfree                 
    B _rfree_exit

_rfree_exit_zero
    MOVS r0, #0

_rfree_exit
    POP {r4-r7, pc}           


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

    MOV r4, r0             

    CMP r4, #32              
    BGE skip_size_adjustment 
    MOV r4, #32        
	
skip_size_adjustment

    LDR r1, =MCB_TOP
    LDR r2, =MCB_BOT
              
	; ----------------
	PUSH {r0-r5, r7-r12}  	; snapshot 
							; change my para
    BL _ralloc         		; go to recursion
	POP {r0-r5, r7-r12}   	; bring back based on snapshot
	;--------------------
	
    POP {lr}             
	BX lr
	
	
	EXPORT _kfree
_kfree
    PUSH {r4, r5, lr}         


    MOV r4, r0                
    LDR r5, =HEAP_TOP
    LDR r5, [r5]               
    LDR r6, =HEAP_BOT
    LDR r6, [r6]              


    CMP r4, r5
    BLT invalid_address       
    CMP r4, r6
    BGT invalid_address     

    LDR r7, =MCB_TOP
    LDR r7, [r7]             
    SUB r4, r4, r5           
    LSRS r4, r4, #4           
    ADD r4, r4, r7     

    MOV r0, r4                 
    BL _rfree                 


    CMP r0, #0
    BEQ invalid_address        

    MOV r0, r4                
    POP {r4, r5, pc}           

invalid_address
    MOV r0, #0                 
    POP {r4, r5, pc}    




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