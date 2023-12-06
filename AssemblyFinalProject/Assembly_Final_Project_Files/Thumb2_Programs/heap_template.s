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
        EXPORT _kinit
_kinit
        PUSH    {R4-R7, LR}        
        LDR     R0, =0x20006800    
        MOV     R1, #0x4000         
        STRH    R1, [R0]            
        ADD     R0, R0, #2   
		
		EXPORT	_heap_init
_heap_init
        PUSH    {R4-R7, LR}            
        LDR     R0, =MCB_TOP           
        LDR     R1, =MAX_SIZE           
        ORR     R1, R1, #1            
        STRH    R1, [R0]

        ADD     R0, R0, #2           
        LDR     R2, =MCB_BOT           
ZeroLoop
        CMP     R0, R2                  
        BGE     DoneZeroing           
        MOV     R1, #0                
        STRH    R1, [R0]              
        ADD     R0, R0, #2           
        B       ZeroLoop             

DoneZeroing
        POP     {R4-R7, PC}           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
        EXPORT  _rfree
_rfree
        PUSH    {R4-R7, LR}                
        LDRH    R1, [R0]                   
        BICS    R1, R1, #1             
        STRH    R1, [R0]                
        MOV     R2, R0
        LDR     R3, =0x20006800      
		SUBS    R3, R0, R3            

        MOVS    R4, #16                      
        MUL    R3, R3, R4                
        TST     R3, R3             
        BNE     CheckRightBuddy       

        SUBS    R2, R2, R3                 
        B       CheckBuddy

CheckRightBuddy
        ADDS    R2, R2, R3             

CheckBuddy
        LDRH    R4, [R2]
        ANDS    R5, R4, #1           
        BNE     AllocationDone      

        ; Merge with buddy
        ADDS    R3, R3, R3            
        STRH    R3, [R0]              
        MOVS    R4, #0                      
        STRH    R4, [R2]

        BL      _rfree

AllocationDone
        POP     {R4-R7, PC}           

        END
			
		EXPORT	_kalloc
_kalloc
        PUSH    {R4-R7, LR}            

        LDR     R1, =MIN_SIZE   
        CMP     R0, R1       
        BGE     SizeOK                
        MOV     R0, R1                      

SizeOK
        LDR     R1, =MCB_TOP             
        LDR     R2, =MCB_BOT             
        BL      _ralloc                  

        POP     {R4-R7, PC}                  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
        PUSH    {R4-R7, LR}              


        LDR     R1, =0x20001000           
        LDR     R2, =0x20004FE0           
        CMP     R0, R1                     
        BLT     InvalidAddress           
        CMP     R0, R2                   
        BGT     InvalidAddress          

        SUBS    R0, R0, R1        
        LSRS    R0, R0, #4              

        LDR     R1, =0x20006800            
        ADDS    R0, R0, R1                 

        BL      _rfree                  

        CMP     R0, #0
        BEQ     InvalidAddress            

FreeDone
        POP     {R4-R7, PC}               

InvalidAddress
        MOV     R0, #0                    
        POP     {R4-R7, PC}                

		BL 		_rfree
        END

        
=======

        EXPORT _kinit
_kinit
        PUSH    {R4-R7, LR}        
        LDR     R0, =0x20006800    
        MOV     R1, #0x4000         
        STRH    R1, [R0]            
        ADD     R0, R0, #2           

ZeroLoop
        CMP     R0, #0x20006BFE     
        BGE     DoneZeroing           
        MOV     R1, #0                
        STRH    R1, [R0]            
        ADD     R0, R0, #2
        B       ZeroLoop         
DoneZeroing
        POP     {R4-R7, PC}            

        END
			
			        EXPORT _ralloc
_ralloc
        PUSH    {R4-R11, LR}              

        SUBS    R3, R2, R1                
        ADDS    R3, R3, #2   
        LSRS    R4, R3, #1   
        ADDS    R5, R1, R4               

        SUBS    R1, R1, #0x20006800       
        SUBS    R5, R5, #0x20006800      
        SUBS    R2, R2, #0x20006800      

        LDRH    R6, [R0, R1]               
        AND    R7, R6, #1                
        BNE     TryRightHalf               

        LSLS    R6, R6, #4         
        LSLS    R4, R4, #4             

        CMP     R0, R4                    
        BHI     TryRightHalf             

        ADDS    R2, R1, R4             
        PUSH    {R0, R1, R2}            
        BL      _ralloc                  
        POP     {R0, R1, R2}             

        CMP     R0, #0                
        BNE     AllocationSuccessful     

TryRightHalf
        ADDS    R1, R5, #0                
        PUSH    {R0, R1, R2}            
        BL      _ralloc                   
        POP     {R0, R1, R2}             
        B       AllocationDone         

AllocationSuccessful
        LDRH    R6, [R0, R1]              
        ORRS    R6, R6, #1            
        STRH    R6, [R0, R1]           

AllocationDone
        MOV     R0, #0                     
        POP     {R4-R11, PC}              

        END
			
