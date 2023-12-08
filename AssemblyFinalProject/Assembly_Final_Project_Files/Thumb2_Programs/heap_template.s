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
    PUSH {r4-r7, lr}

    MOV r4, r0                
    MOV r5, r1                 
    MOV r6, r2                 
    LDR r7, =MCB_ENT_SZ
    LDR r7, [r7]
    SUB r2, r6, r5             
    ADD r2, r2, r7             
    LSRS r3, r2, #1           
    ADD r7, r5, r3
    MOV r0, #0                
    LSLS r2, r2, #4           
    LSLS r3, r3, #4          

    CMP r4, r3
    BHI _ralloc_occupy

    SUB r2, r7, #MCB_ENT_SZ
    MOV r0, r4
    MOV r1, r5
    MOV r2, r2
    BL _ralloc          
    CMP r0, #0
    BNE _ralloc_return

    MOV r0, r4
    MOV r1, r7
    MOV r2, r6
    BL _ralloc               
    B _ralloc_return
	LDR r2, =MCB_TOP

_ralloc_occupy
    ADD r1, r5, r2
    LDR r1, [r1]
    ANDS r1, r1, #1
    CMP r1, #0
    BEQ _ralloc_space_check
    MOV r0, #0                
    B _ralloc_return

_ralloc_space_check
    ADD r1, r5, r2
    LDRH r1, [r1]
    CMP r1, r2
    BLO _ralloc_exit_zero
    ORRS r1, r2, #1
    ADD r1, r5, r2
    STRH r1, [r1]       

    LDR r1, =HEAP_TOP
    SUB r0, r5, r2
    LSLS r0, r0, #4
    ADD r0, r1, r0 

_ralloc_return
    POP {r4-r7, pc}          

_ralloc_exit_zero
    MOV r0, #0               
    POP {r4-r7, pc}           
		
		
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
    STRH r5, [r4]           

    LDR r4, =MCB_TOP
    ADD r4, r4, #2          

init_loop
    LDR r5, =MCB_BOT
    CMP r4, r5
    BGE end_init
    MOVS r5, #0
    STRH r5, [r4]           
    ADD r4, r4, #2        
    B init_loop

end_init
    POP {r4, r5, pc}


	EXPORT _kalloc
_kalloc
    PUSH {r4, lr}          

    MOV r4, r0             

    CMP r4, #32              
    BGE skip_size_adjustment 
    MOV r4, #32           
skip_size_adjustment
    LDR r0, =MCB_TOP
    LDR r1, =MCB_BOT
    MOV r0, r4              
    LDR r1, [r1]      
    LDR r2, [r0]             

    BL _ralloc            

    POP {r4, pc}             
	
	
	
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

    LDR r4, =MCB_TOP       
    LDR r5, =MCB_BOT       

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