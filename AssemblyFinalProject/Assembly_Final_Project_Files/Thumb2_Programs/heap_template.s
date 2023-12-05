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
		EXPORT	_heap_init
_heap_init
        PUSH    {R4-R7, LR}             ; Save registers and the return address

        ; Initialize the first MCB entry
        LDR     R0, =MCB_TOP            ; Load the starting address of MCB into R0
        LDR     R1, =MAX_SIZE           ; Load the total size (16KB) into R1
        ORR     R1, R1, #1              ; Set the least significant bit (indicate free space)
        STRH    R1, [R0]                ; Store the value at the first MCB entry

        ; Zero out the rest of the MCB entries
        ADD     R0, R0, #2              ; Move to the next MCB entry
        LDR     R2, =MCB_BOT            ; Load MCB_BOT into R2 for comparison
ZeroLoop
        CMP     R0, R2                  ; Check if the end of MCB is reached
        BGE     DoneZeroing             ; If so, we are done
        MOV     R1, #0                  ; Load 0 into R1
        STRH    R1, [R0]                ; Store 0 into the current MCB entry
        ADD     R0, R0, #2              ; Move to the next MCB entry
        B       ZeroLoop                ; Repeat the loop

DoneZeroing
        POP     {R4-R7, PC}             ; Restore registers and return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
        EXPORT  _rfree
_rfree
        PUSH    {R4-R7, LR}                  ; Save registers and the return address

        ; R0 contains the MCB address to deallocate
        ; Load MCB entry
        LDRH    R1, [R0]                     ; Load the MCB entry
        BICS    R1, R1, #1                   ; Clear the allocated bit (LSB)
        STRH    R1, [R0]                     ; Update the MCB entry

        ; Calculate buddy address
        MOV     R2, R0                       ; Copy current MCB address to R2
        LDR     R3, =0x20006800              ; Load the MCB base address into R3
		SUBS    R3, R0, R3                   ; Calculate offset from MCB base

        MOVS    R4, #16                      ; Block size multiplier
        MUL    R3, R3, R4                   ; Calculate block size
        TST     R3, R3                       ; Test if offset is even or odd
        BNE     CheckRightBuddy              ; If odd, check right buddy

        ; Check left buddy
        SUBS    R2, R2, R3                   ; Calculate left buddy address
        B       CheckBuddy

CheckRightBuddy
        ; Check right buddy
        ADDS    R2, R2, R3                   ; Calculate right buddy address

CheckBuddy
        ; Load buddy MCB entry
        LDRH    R4, [R2]
        ANDS    R5, R4, #1                   ; Check if the buddy is allocated
        BNE     AllocationDone               ; If buddy is allocated, we are done

        ; Merge with buddy
        ADDS    R3, R3, R3                   ; Double the block size
        STRH    R3, [R0]                     ; Update the current MCB entry
        MOVS    R4, #0                       ; Clear the buddy MCB entry
        STRH    R4, [R2]

        ; Recursively call _rfree with the merged block
        BL      _rfree

AllocationDone
        POP     {R4-R7, PC}                  ; Restore registers and return

        END
			
		EXPORT	_kalloc
_kalloc
        PUSH    {R4-R7, LR}                  ; Save registers and the return address

        ; R0 contains the size to be allocated
        ; Adjust size to at least the minimum allocation size
        LDR     R1, =MIN_SIZE                ; Load minimum allocation size
        CMP     R0, R1                       ; Compare requested size with minimum size
        BGE     SizeOK                       ; If requested size >= minimum size, it's OK
        MOV     R0, R1                       ; Adjust size to minimum size

SizeOK
        ; Prepare parameters for _ralloc
        LDR     R1, =MCB_TOP                 ; Load the address of the first MCB entry
        LDR     R2, =MCB_BOT                 ; Load the address of the last MCB entry
        BL      _ralloc                      ; Call _ralloc recursively

        ; Allocation result is in R0
        POP     {R4-R7, PC}                  ; Restore registers and return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
        PUSH    {R4-R7, LR}                  ; Save registers and the return address

        ; R0 contains the pointer to be freed
        ; Validate the address
        LDR     R1, =0x20001000              ; Load the top of heap space
        LDR     R2, =0x20004FE0              ; Load the bottom of heap space
        CMP     R0, R1                       ; Compare address with heap top
        BLT     InvalidAddress               ; If less, it's invalid
        CMP     R0, R2                       ; Compare address with heap bottom
        BGT     InvalidAddress               ; If greater, it's invalid

; Calculate corresponding MCB index
        SUBS    R0, R0, R1                   ; Subtract heap top from address
        LSRS    R0, R0, #4                   ; Divide by 16 to get MCB index

        ; Load the base MCB address into a register
        LDR     R1, =0x20006800              ; Load the base MCB address into R1
        ADDS    R0, R0, R1                   ; Add base MCB address

        ; Call _rfree with MCB index
        BL      _rfree                       ; Call _rfree

        ; Check if _rfree returned a valid address
        CMP     R0, #0
        BEQ     InvalidAddress               ; If _rfree returned 0, address is invalid

FreeDone
        POP     {R4-R7, PC}                  ; Restore registers and return

InvalidAddress
        ; Handle invalid address case
        ; This section can be modified based on how you want to handle invalid addresses
        MOV     R0, #0                       ; Set return value to 0 (NULL) for invalid address
        POP     {R4-R7, PC}                  ; Restore registers and return

	_rfree

        END

        EXPORT _kinit
_kinit
        PUSH    {R4-R7, LR}             ; Save registers and the return address
        LDR     R0, =0x20006800         ; Load the starting address of MCB into R0
        MOV     R1, #0x4000             ; Load the value 0x4000 into R1
        STRH    R1, [R0]                ; Store the value 0x4000 at the first MCB entry
        ADD     R0, R0, #2              ; Move to the next MCB entry

        ; Zero out the rest of the MCB entries
ZeroLoop
        CMP     R0, #0x20006BFE         ; Check if the end of MCB is reached
        BGE     DoneZeroing             ; If so, we are done
        MOV     R1, #0                  ; Load 0 into R1
        STRH    R1, [R0]                ; Store 0 into the current MCB entry
        ADD     R0, R0, #2              ; Move to the next MCB entry
        B       ZeroLoop                ; Repeat the loop

DoneZeroing
        POP     {R4-R7, PC}             ; Restore registers and return

        END
			
			        EXPORT _ralloc
_ralloc
        PUSH    {R4-R11, LR}               ; Save registers and the return address

        ; R0 = size, R1 = left boundary, R2 = right boundary
        ; Convert MCB index to actual memory address
        SUBS    R3, R2, R1                 ; Calculate entire range
        ADDS    R3, R3, #2                 ; Adjust for size of MCB entry
        LSRS    R4, R3, #1                 ; Calculate half the range
        ADDS    R5, R1, R4                 ; Calculate midpoint

        ; Convert MCB address to array index
        SUBS    R1, R1, #0x20006800        ; Convert left boundary to array index
        SUBS    R5, R5, #0x20006800        ; Convert midpoint to array index
        SUBS    R2, R2, #0x20006800        ; Convert right boundary to array index

        ; Check if the size can fit in the half-size block
        LDRH    R6, [R0, R1]               ; Load the value at the left boundary (current block)
        ANDS    R7, R6, #1                 ; Check if the current block is allocated (LSB = 1)
        BNE     TryRightHalf               ; If block is already allocated, try the right half

        ; Calculate actual size for the entire and half blocks
        LSLS    R6, R6, #4                 ; Actual size of the entire block
        LSLS    R4, R4, #4                 ; Actual size of the half block

        CMP     R0, R4                     ; Compare requested size with half block size
        BHI     TryRightHalf               ; If requested size > half block size, try right half

        ; Fits in left half, continue allocation in this half
        ADDS    R2, R1, R4                 ; New right boundary is the midpoint
        PUSH    {R0, R1, R2}               ; Save size, left, and right parameters on stack
        BL      _ralloc                    ; Recursive call to _ralloc with adjusted boundaries
        POP     {R0, R1, R2}               ; Restore size, left, and right parameters from stack

        ; Check the result of the recursive call
        CMP     R0, #0                     ; Compare the result with 0 (NULL)
        BNE     AllocationSuccessful       ; If result is not 0, allocation was successful

TryRightHalf
        ; Prepare for right half allocation
        ; Adjust left boundary to midpoint for the recursive call
        ADDS    R1, R5, #0                 ; New left boundary is the midpoint
        PUSH    {R0, R1, R2}               ; Save size, left, and right parameters on stack
        BL      _ralloc                    ; Recursive call to _ralloc with adjusted boundaries
        POP     {R0, R1, R2}               ; Restore size, left, and right parameters from stack
        B       AllocationDone             ; Jump to the end after allocation is done

AllocationSuccessful
        ; Allocation was successful, update the MCB
        ; The left boundary points to the MCB entry that needs updating
        LDRH    R6, [R0, R1]               ; Load the current MCB value
        ORRS    R6, R6, #1                 ; Set the allocation bit
        STRH    R6, [R0, R1]               ; Store the updated MCB value

AllocationDone
        MOV     R0, #0                     ; Set R0 to 0 (NULL) in case of failure
        POP     {R4-R11, PC}               ; Restore registers and return

        END
			
