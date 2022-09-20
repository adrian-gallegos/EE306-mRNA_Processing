; Program5.asm
; Name(s): Adrian Gallegos
; UTEid(s): ag76424
; Continuously reads from x3600 making sure its not reading duplicate
; symbols. Processes the symbol based on the program description
; of mRNA processing.
    .ORIG x3000
; set up the keyboard interrupt vector table entry
; M[x0180] <- x2600
    LD  R0, KBISR
	STI R0, KBINTVec
; enable keyboard interrupts
; KBSR[14] <- 1 ==== M[xFE00] = x4000
    LD  R0, KBINTEN
    STI R0, KBSR
    
; Initialize global to be 0
    ; M[x3600] -> 0
    AND R0, R0, #0
    STI R0, GLOB
    
; Start codon counter (there's only 1 start codon)
    AND R2, R2, #0
    ADD R2, R2, #1
    
; This loop is the proper way to read an input
Loop
    LDI R0, GLOB
    BRz Loop
    BR  getA_start    ; ***** don't wanna output an unknown valid character
    ; Here means x3600 has a valid input
ValidCharacter  ; *****
    TRAP x21    ; Output character out  **** outputed a valid character w/o regard to what it was (problem because if 1st character is A, it's not counted toward start codon)
    ; Reset GLOB to 0
    AND R0, R0 #0
    STI R0, GLOB
    ; If R2 is positive, start codon has NOT been found ***
    ADD R2, R2, #0
    BRnz getU_stop
    ; Process it in keeping with FSM
getA_start
    LDI R0, GLOB
    BRz getA_start    ; a valid character has been typed
    ; Begin searching for AUG start codon
    LD  R1, NegA
    ADD R1, R0, R1      ; checks for A
    BRz foundA_start
    BR  ValidCharacter            ; still need to output valid character (even if it's not A)
foundA_start
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB        ; ensures we're not reading the same character
getU_start
    LDI R0, GLOB
    BRz getU_start
    LD  R1, NegU
    ADD R1, R0, R1      ; checks for AU
    BRz foundU_start
    BR  ValidCharacter
foundU_start
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB
getG_start
    LDI R0, GLOB
    BRz getG_start
    LD  R1, NegG
    ADD R1, R0, R1      ; checks for AUG
    BRz foundG_start
    BR  ValidCharacter
foundG_start  ; <-- start codon found (need to display '|' after G)
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB        ; shouldn't need character anymore
    ; Displays '|' after start codon
    LD  R0, Bracket
    TRAP x21
    ADD R2, R2, #-1     ; ensures there's only 1 start codon
    ; Begin looking for UAG, UAA, UGA
getU_stop
    LDI R0, GLOB
    BRz getU_stop
    LD  R1, NegU
    ADD R1, R0, R1      ; checks for U
    BRz foundU_stop
    BR  ValidCharacter
foundU_stop
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB
getA_stop               ; 'A' is the middle character here
    LDI R0, GLOB
    BRz getA_stop
    LD  R1, NegA
    ADD R1, R0, R1      ; checks for UA
    BRz foundA_stop
    BR  maybe_getG_stop   ; 'G' is still possible ***** IF 'U', NEED TO GO TO getU_stop
foundA_stop
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB
    BR  getG_stop
maybe_getG_stop           ; G is the middle character here
    LDI R0, GLOB        ; ***
    BRz maybe_getG_stop ; ***
    LD  R1, NegG
    ADD R1, R0, R1      ; checks for UG
    BRz found_maybeG_stop
    BR  getU_stop      ; ***** IF 'U', NEED TO GO TO getU_stop (don't go to ValidCharacter because would display unknown valid character)
found_maybeG_stop
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB
    BR  maybe_getA_stop   ; 'A' is the only valid character to create UGA the stop codon
getG_stop               ; 'G' is the last character of the stop codon
    LDI R0, GLOB
    BRz getG_stop
    LD  R1, NegG
    ADD R1, R0, R1
    BRz foundG_stop
    BR  maybe_getA_stop
foundG_stop
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB
    BR  STOP
maybe_getA_stop         ; 'A' is the last character of the stop codon
    LDI R0, GLOB
    BRz maybe_getA_stop
    LD  R1, NegA
    ADD R1, R0, R1
    BRz found_maybeA_stop
    BR  getU_stop
found_maybeA_stop
    TRAP x21
    AND R0, R0, #0
    STI R0, GLOB

STOP
; Repeat unil Stop Codon detected
    HALT
KBINTVec  .FILL x0180
KBSR   .FILL xFE00
KBISR  .FILL x2600
KBINTEN  .FILL x4000
GLOB   .FILL x3600
NegA    .FILL #-65
NegC    .FILL #-67
NegG    .FILL #-71
NegU    .FILL #-85
Bracket .FILL x7C

	.END

; Interrupt Service Routine
; Keyboard ISR runs when a key is struck
; Checks for a valid RNA symbol and places it at x3600
    .ORIG x2600
    ; Save R0, R1
    ST  R0, INT_SAVE_R0
    ST  R0, INT_SAVE_R1
    
    LDI R0, KBDR    ; Get keystroke
    ; Check if R0 has an A, C, G, or U (could copy code from program 4 "Input_Valid")
    LD  R1, INegA
    ADD R1, R0, R1
    BRz Valid
    LD  R1, INegC
    ADD R1, R0, R1
    BRz Valid
    LD  R1, INegG
    ADD R1, R0, R1
    BRz Valid
    LD  R1, INegU
    ADD R1, R0, R1
    BRz Valid
    BR  Done
Valid
     ; Write R0 to Global
     STI R0, IGLOB
Done
    ; Restore R0, R1
    LD  R0, INT_SAVE_R0
    LD  R1, INT_SAVE_R1
    
    RTI
        
KBDR  .FILL xFE02
IGLOB  .FILL x3600
INegA    .FILL #-65
INegC    .FILL #-67
INegG    .FILL #-71
INegU    .FILL #-85
INT_SAVE_R0     .BLKW #1
INT_SAVE_R1     .BLKW #1

		.END
