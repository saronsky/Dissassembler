*-----------------------------------------------------------
* Title      : CSS 422 Disassembler - Team Sushi
* Written by : Shane Clarke, Ahmad Yousif, Simon Arsonsky, HsinYu Chin
* Date       : 8.16.20
* Description: This program disassembles an .S68 source file to convert
*              EASy68K machine code to real code.
*-----------------------------------------------------------
CR            EQU     $0D
LF            EQU     $0A
TAB           EQU     $09

    ORG       $1000
START:                  ; first instruction of program

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Initialize setting  
INIT:
    ; Clear register
    CLR       D7
    MOVE.L    #0,A1
    MOVE.L    #0,A2
    MOVE.L    #0,A3
    
WELCOME:
    LEA       WEL_MSG,A1         ; DISPLAY WELCOME MESSAGE
    MOVE.B    #14,D0
    TRAP      #15

    LEA       TEAM_MSG,A1        ; DISPLAY TEAM MESSAGE
    MOVE.B    #14,D0
    TRAP      #15
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Collect start and end addresses from user  
ADDR:
    LEA       START_ADDR,A1      ; Collect starting address
    MOVE.B    #14,D0
    TRAP      #15
    
    MOVEA.W   ADDR_RESPONSE,A1   ; Collect ending address
    MOVE.B    #2,D0
    TRAP      #15
    
    BSR       INPUT
    MOVE.L    D2,A2
   
    MOVE      #14,D0
    LEA       END_ADDR,A1
    TRAP      #15
    
    MOVEA.W   ADDR_RESPONSE,A1
    MOVE.B    #2,D0
    TRAP      #15
    
    BSR       INPUT
    MOVE.L    D2,A3  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Main loop through the input data    
LOOP:
    CMP.B     #25,D7
    BEQ       PRCS_ASK_TO_CONTINUE
    ADD.B     #1,D7
	
    BSR       PRINT_CR
    CLR.L     D1
    CMPA.L    A3,A2
    BGE       PRCS_ASK_TO_RESTART
    
    LEA       tempMsg,A1
    MOVE.W    A2,D0
    MOVE.L    #8,D1              ; padding size
    JSR       PRINT_REG_AS_ASCII
    
    MOVE.W    (A2)+,D1
    
    ; Save the command from D1 into tempCmd variable
    LEA       tempCmd,A7
    MOVE.W    D1,(A7)

    ; Jump table
    JSR       __NOP
    JSR       __MOVE
    JSR       __MOVEM
    JSR       __ADD
    JSR       __SUB
    JSR       __DIVU_W
    JSR       __1100      ; This could be either MULS.W or AND command
    JSR       __1110      ; This could be either ASL or LSL command
    JSR       __NOT
    JSR       __LEA
    JSR       __JSR
    JSR       __RTS
    JSR       __BRA
    JSR       __BCC
    JSR       __BEQ
    JSR       __BGT
    JSR       __BLE
    
    JSR       __UNKNOWN
    JMP       LOOP

;;;;;;;;;;;;;;;;;;;;
;; UNKNOWN
__UNKNOWN
    LEA       sUnknown,A1   ; address of string
    MOVE.B    #14, D0       ; no parameter printing required
    TRAP      #15

    LEA       tempMsg, A1   ; Load the tempMsg address in A1  
    LEA       tempCmd,A7    ; address of string
    MOVE.B    #'$',(A1)+
    MOVE.W    (A7),D0
    MOVE.W    #8,D1

    JSR       PRINT_REG_AS_ASCII
  
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;
;; NOP
__NOP:
    LEA       tempCmd, A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE      D1,D0
    CMP       #$4E71,D0       ; 0100 1110 0111 0001
    BNE       CMD_RTS
  
    LEA       sNop,A1         ; address of string
    MOVE.L    #0,D3           ; no parameter printing required
    BSR         CMD_PRINT
  
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;
;; MOVE
__MOVE:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE      D1,D0
    AND.W     #$C000,D0       ; 1100 0000 0000 0000
    CMP       #0,D0           ; 0000 0000 0000 0000
    BNE       CMD_RTS
  
    MOVE      D1,D0
    AND.W     #$F000,D0       ; 1111 0000 0000 0000
    CMP       #0,D0           ; 0000 0000 0000 0000
    BEQ       CMD_RTS

  ;; INPUT for CMD_PRINT
  ;; A1 - contains the message to write
  ;; D2 - Two byte command data
  ;; D3 - Boolean flag (0 or 1) indicating if command required parameter printing
  ;; D4 -  of parameter string to zero pad it
    LEA       sMove,A1    ; address of string
    MOVE.L    #0,D3       ; no parameter printing required
    BSR       CMD_PRINT  
  
  ;; INPUT for PRINT_SIZE
  ;; D0 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D0         ; Read tempCmd into D0
    AND.W     #$3000,D0
    LSR.W     #8,D0
    LSR.W     #4,D0
    BSR       PRINT_MOVE_SIZE  

  ;; Print source register/address
  ;; INPUT for :
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE      D1,D2
    AND.W     #$0038,D2
    LSR.W     #3,D2
  
    MOVE      D1,D3
    AND.W     #$3000,D3
    LSR.W     #8,D3
    LSR.W     #4,D3

    MOVE.W    D0,D4
    AND.W     #$0005,D4
    CMP.W     #1,D0
    BEQ       SRC_MOVE_SIZE_L
    CMP.W     #0,D4
    BEQ       SRC_MOVE_SIZE_W  
    BRA       SRC_MOVE_CONT
    
SRC_MOVE_SIZE_W:
    MOVE.W    #3, D3
    BRA       SRC_MOVE_CONT
  
SRC_MOVE_SIZE_L:
    MOVE.W    #2,D3
 
SRC_MOVE_CONT: 
    BSR       PRINT_REG
  
  ;; Print separating comma between the source and destination
    BSR       PRINT_COMMA
  
  ;; Print destination register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Reg number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd, A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0E00,D0
    LSR.W     #8,D0
    LSR.W     #1,D0
  
    MOVE      D1,D2
    AND.W     #$01C0,D2
    LSR.W     #6,D2
  
    CMP.W     #1,D0
    BEQ       DEST_MOVE_SIZE_L
    MOVE.W    #3,D3
    BRA       DEST_MOVE_CONT
    
DEST_MOVE_SIZE_L:
    MOVE.W    #2,D3

DEST_MOVE_CONT:  
    BSR       PRINT_REG
    BRA       BRA_LOOP
  
;;;;;;;;;;;;;;;;;;;;
;; MOVEM
__MOVEM:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE      D1,D0
    AND.W     #$FB80,D0      ; 1111 1011 1000 0000
    CMP.W     #$4880,D0      ; 0100 1000 1000 0000
    BNE       CMD_RTS
  
  ;; INPUT for CMD_PRINT
  ;; A1 - contains the message to write
  ;; D2 - Two byte command data
  ;; D3 - Boolean flag (0 or 1) indicating if command required parameter printing
  ;; D4 - Size of parameter string to zero pad it
    LEA       sMovem,A1    ; address of string
    MOVE.L    #0,D3       ; no parameter printing required
    BSR       CMD_PRINT
  
  ;; INPUT for PRINT_SIZE
  ;; D0 - Size parameter (B=0, W=1, L=2)
  ;; Size bit for MOVEM has only two possibilites: W=0 and L=1.
    LEA       tempCmd,A1
    MOVE.W    (A1),D0         ; Read tempCmd into D0
    AND.W     #$0040,D0        ; Isolate MOVEM size bit
    LSR.W     #6,D0            ; Shift size bit to the right end
    ADD.W     #1,D0            ; Add 1 to the size bit to make W=1 and L=2 for PRINT_SIZE
    BSR       PRINT_SIZE
  
  ;; Print destination register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Reg number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0400,D0        ; 0000 0100 0000 0000  
    CMP.W     #0,D0
    BEQ       PRCS_MOVEM_DR0
    JMP       PRCS_MOVEM_DR1
  
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;
;; ADD
__ADD:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$F000,D0      ; 1111 0000 0000 0000
    CMP.W     #$D000,D0      ; 1101 0000 0000 0000
    BNE       CMD_RTS
  
  ;; Fail if we have ADDA instruction
    MOVE.W    D1,D0
    JSR       VALIDATE_ADD_OR_SUB_OPCODE

  ;; put printing code here

    LEA       sAdd,A1    ; address of string
    MOVE.L    #0, D3      ; no parameter printing required
    BSR       CMD_PRINT 
  
  ;; INPUT for PRINT_SIZE
  ;; D0 - Size parameter (B=0, W=1, L=2)
    LEA       tempCmd, A1
    MOVE.W    (A1),D0         ; Read tempCmd into D0
    AND.W     #$00C0, D0
    LSR.W     #6,D0
    BSR       PRINT_SIZE     

  ;; Print the source and destination parameters
    JSR       PRCS_OPMODE_REG
  
    BRA       BRA_LOOP


;;;;;;;;;;;;;;;;;;;;
;; SUB
__SUB:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$F000,D0      ; 1111 0000 0000 0000
    CMP.W     #$9000,D0      ; 1001 0000 0000 0000
    BNE       CMD_RTS
  
  ;; Fail if we have SUBA instruction
    MOVE.W    D1,D0
    JSR       VALIDATE_ADD_OR_SUB_OPCODE

  ;; put printing code here

    LEA       sSub,A1    ; address of string
    MOVE.L    #0,D3      ; no parameter printing required
    BSR       CMD_PRINT  
  
  ;; INPUT for PRINT_SIZE
  ;; D0 - Size parameter (B=0, W=1, L=2)
    LEA       tempCmd, A1
    MOVE.W    (A1),D0         ; Read tempCmd into D0
    AND.W     #$00C0, D0
    LSR.W     #6,D0
    BSR       PRINT_SIZE   
  
  ;; Print the source and destination parameters
    JSR       PRCS_OPMODE_REG
  
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;
;; DIVU.W
__DIVU_W:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$F000,D0      ; 1111 0000 0000 0000
    CMP.W     #$8000,D0      ; 1000 0000 0000 0000
    BNE       CMD_RTS

  ;; put printing code here

    LEA       sDivuW,A1    ; address of string
    MOVE.L    #0, D3        ; parameter printing required
    JSR       CMD_PRINT  

  ;; Print the source/destination paramter
    JSR       PRCS_MULS_OR_DIVU_REG  
  
    BRA       BRA_LOOP
  
;;;;;;;;;;;;;;;;;;;;
;; BRA Command
__BRA:
    LEA       tempCmd, A1
    MOVE.W    (A1),D1       ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$FF00,D0      ; 1111 1111 0000 0000
    CMP.W     #$6000,D0      ; 0110 0000 0000 0000
    BNE       CMD_RTS
  
    LEA       sBra, A1
    MOVE.L    #0,D3         ; no parameter printing required
    BSR       CMD_PRINT  

    LEA       tempCmd,A1       
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 1111 1111
    CMP.W     #$00FF,D1      ; 0000 0000 1111 1111
    BEQ       PRCS_BRA_32       ; If last 8 bits are all 1 that means it is 32 bit displacement
  
    LEA       tempCmd, A1
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 0000 0000
    CMP.W     #$0000, D1      ; 0000 0000 0000 0000
    BEQ       PRCS_BRA_16       ; If last 8 bits are all 0 that means it is 16 bit displacement

    BRA PRCS_BRA_8  
  
    BRA BRA_LOOP
  
;;;;;;;;;;;;;;;;;;;;
;; BCC Command
__BCC:
  ; Checks if BCC command
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$FF00,D0      ; 1111 1111 0000 0000
    CMP.W     #$6400,D0      ; 0110 0100 0000 0000
    BNE       CMD_RTS
  
    LEA       sBcc,A1
    MOVE.L    #0,D3         ; no parameter printing required
    BSR       CMD_PRINT
  
  ; Checks if BCC 32-bit displacement
    LEA       tempCmd,A1       
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 1111 1111
    CMP.W     #$00FF,D1      ; 0000 0000 1111 1111
    BEQ       PRCS_BRA_32       ; If last 8 bits are all 1 that means it is 32 bit displacement
  
  ; Checks if BCC 16-bit displacement
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 0000 0000
    CMP.W     #$0000,D1      ; 0000 0000 0000 0000
    BEQ       PRCS_BRA_16       ; If last 8 bits are all 0 that means it is 16 bit displacement

  ; Branches to BCC 32-bit displacement
    BRA       PRCS_BRA_8 
  
;;;;;;;;;;;;;;;;;;;;
;; BEQ Command
__BEQ:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$FF00,D0      ; 1111 1111 0000 0000
    CMP.W     #$6700,D0      ; 0110 0000 0000 0000
    BNE       CMD_RTS
  
    LEA       sBeq,A1
    MOVE.L    #0,D3         ; no parameter printing required
    BSR       CMD_PRINT
  
  ; Checks if BCC 32-bit displacement
    LEA       tempCmd,A1       
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 1111 1111
    CMP.W     #$00FF,D1      ; 0000 0000 1111 1111
    BEQ       PRCS_BRA_32       ; If last 8 bits are all 1 that means it is 32 bit displacement
  
  ; Checks if BCC 16-bit displacement
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 0000 0000
    CMP.W     #$0000,D1      ; 0000 0000 0000 0000
    BEQ       PRCS_BRA_16       ; If last 8 bits are all 0 that means it is 16 bit displacement

  ; Branches to BCC 32-bit displacement
    BRA       PRCS_BRA_8 
  
;;;;;;;;;;;;;;;;;;;;
;; BEQ Command
__BGT:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$FF00,D0      ; 1111 1111 0000 0000
    CMP.W     #$6E00,D0      ; 0110 1110 0000 0000
    BNE       CMD_RTS
  
    LEA       sBgt,A1
    MOVE.L    #0,D3         ; no parameter printing required
    BSR       CMD_PRINT
  
  ; Checks if BCC 32-bit displacement
    LEA       tempCmd,A1       
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 1111 1111
    CMP.W     #$00FF,D1      ; 0000 0000 1111 1111
    BEQ       PRCS_BRA_32       ; If last 8 bits are all 1 that means it is 32 bit displacement
  
  ; Checks if BCC 16-bit displacement
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 0000 0000
    CMP.W     #$0000,D1      ; 0000 0000 0000 0000
    BEQ       PRCS_BRA_16       ; If last 8 bits are all 0 that means it is 16 bit displacement

  ; Branches to BCC 32-bit displacement
    BRA       PRCS_BRA_8 

;;;;;;;;;;;;;;;;;;;;
;; BLE Command
__BLE:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$FF00,D0      ; 1111 1111 0000 0000
    CMP.W     #$6F00,D0      ; 0110 1111 0000 0000
    BNE       CMD_RTS
  
    LEA       sBle,A1
    MOVE.L    #0,D3         ; no parameter printing required
    BSR       CMD_PRINT
  
  ; Checks if BCC 32-bit displacement
    LEA       tempCmd,A1       
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 1111 1111
    CMP.W     #$00FF,D1      ; 0000 0000 1111 1111
    BEQ       PRCS_BRA_32       ; If last 8 bits are all 1 that means it is 32 bit displacement
  
  ; Checks if BCC 16-bit displacement
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; copying current byte into D1
    AND.W     #$00FF,D1      ; 0000 0000 0000 0000
    CMP.W     #$0000,D1      ; 0000 0000 0000 0000
    BEQ       PRCS_BRA_16       ; If last 8 bits are all 0 that means it is 16 bit displacement

  ; Branches to BCC 32-bit displacement
    BRA PRCS_BRA_8

;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;
;; MULS.W or AND
__1100:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1       ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$F000,D0      ; 1111 0000 0000 0000 
    CMP.W     #$C000,D0      ; 1100 0000 0000 0000
    BNE       CMD_RTS
  
    MOVE.W    D1,D0
    AND.W     #$F1C0,D0      ; 1111 0001 1100 0000 
    CMP.W     #$C1C0,D0      ; 1100 0001 1100 0000
    BEQ       PRCS_MULS_W       ; If command is MULS.W than we will process it otherwise it would be an AND command.
  
    JMP       PRCS_AND
    BRA       LOOP
;  0000 0000 0000 0000 1100 0000 0000 0000  

;;;;;;;;;;;;;;;;;;;;
;; NOT command
__NOT:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE      D1,D0
    AND.W     #$FF00,D0      ; 1111 1111 0000 0000
    CMP.W     #$4600,D0      ; 0100 0110 0000 0000
    BNE       CMD_RTS
  
    LEA       sNot,A1         ; address of string
    MOVE.L    #0,D3          ; no parameter printing required
    JSR       CMD_PRINT  
  
  ;; INPUT for PRINT_SIZE
  ;; D0 - Size parameter (B=0, W=1, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D0         ; Read tempCmd into D0
    AND.W     #$00C0,D0
    LSR.W     #6,D0
    BSR       PRINT_SIZE 
  
  ;; Print source register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE.W    D1,D2
    AND.W     #$0038,D2
    LSR.W     #3,D2

    MOVE.W    D1,D3
    AND.W     #$00C0,D3
    LSR.W     #6,D3
  
    JSR       PRINT_REG 
  
    BRA       BRA_LOOP
;****************************************

;;;;;;;;;;;;;;;;;;;;
;; ASL or LSL command
__1110:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$F000,D0      ; 1111 0000 0000 0000
    CMP.W     #$E000,D0      ; 1110 0000 0000 0000
    BNE       CMD_RTS
  
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0018,D0
    CMP.W     #$0000,D0
    BEQ       PRCS_ASL
    CMP.W     #$0008,D0
    BEQ       PRCS_LSL  
  
    MOVE.W    D1,D0
    AND.W     #$0FC0,D0
    CMP.W     #$01C0,D0
    BEQ       PRCS_ASL
    CMP.W     #$03C0,D0
    BEQ       PRCS_LSL  
  
    RTS
;**************

;;;;;;;;;;;;;;;;;;;;
;; LEA command
__LEA:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$F1C0,D0      ; 1111 0001 1100 0000
    CMP.W     #$41C0,D0      ; 0100 0001 1100 0000
    BNE       CMD_RTS
  
    LEA       sLea,A1         ; address of string
    MOVE.L    #0,D3          ; no parameter printing required
    JSR       CMD_PRINT  
  
  ;; Print source register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE.W    D1,D2
    AND.W     #$0038,D2
    LSR.W     #3,D2
  
    MOVE.W    D1,D3
    AND.W     #$0001,D3
    CMP.W     #$0000,D3
    BEQ       LEA_SIZE_W
    MOVE.W    #2,D3          ; set the size to (L)
    BRA       LEA_CONT
    
LEA_SIZE_W:
    MOVE.W    #3,D3          ; set the size to (W)
    
LEA_CONT:  
    JSR       PRINT_REG 
  
  ;; Print separating comma between the source and destination
    JSR       PRINT_COMMA
  
  ;; Print destination register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Reg number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0E00,D0
    LSR.W     #8,D0
    LSR.W     #1,D0
  
    MOVE.W    #1,D2
    MOVE.W    #0,D3
    JSR       PRINT_REG 
  
    BRA       BRA_LOOP  
;****************************************

;;;;;;;;;;;;;;;;;;;;
;; JSR command
__JSR:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$FFC0,D0      ; 1111 1111 1100 0000
    CMP.W     #$4E80,D0      ; 0100 1110 1000 0000
    BNE       CMD_RTS
  
    LEA       sJsr,A1         ; address of string
    MOVE.L    #0,D3          ; no parameter printing required
    JSR       CMD_PRINT  
  
  ;; Print source register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE.W    D1,D2
    AND.W     #$0038,D2
    LSR.W     #3,D2
  
    MOVE.W    D1,D3
    AND.W     #$0001,D3
    CMP.W     #$0000,D3
    BEQ       LEA_SIZE_W
    MOVE.W    #2,D3          ; set the size to (L)
    BRA       LEA_CONT
    
JSR_SIZE_W:
    MOVE.W    #3,D3          ; set the size to (W)
  
JSR_CONT:
    JSR       PRINT_REG 
    BRA       BRA_LOOP  
;****************************************

;;;;;;;;;;;;;;;;;;;;
;; RTS command  
__RTS:
    LEA       tempCmd,A1
    MOVE.W    (A1),D1        ; Read tempCmd into D1
    MOVE.W    D1,D0
    CMP.W     #$4E75,D0      ; 0100 1110	0111 0101
    BNE       CMD_RTS
  
    LEA       sRts,A1        ; address of string
    MOVE.L    #0,D3          ; no parameter printing required
    BSR       CMD_PRINT  
  
    BRA       BRA_LOOP
  
BRA_LOOP:  
    BRA       LOOP
  
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;^^^^^^^^^  END OF COMMAND LIST ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;;;;;;;;;;;;;;;;;;;;;;;;
;; Continue processing 20 items per page
PRCS_ASK_TO_CONTINUE:
    LEA       CONTINUE_MSG,A1     ; DISPLAY CONTINUE MESSAGE
    MOVE.B    #14,D0
    TRAP      #15

    MOVE.B    #5, D0
    TRAP      #15
    
    MOVE.B    #0,D7

    BRA       BRA_LOOP
    
;;;;;;;;;;;;;;;;;;;;;;;;
;; Continue processing per page
PRCS_ASK_TO_RESTART
    LEA       RESTART_MSG,A1      ; DISPLAY CONTINUE MESSAGE
    MOVE.B    #14,D0
    TRAP      #15

    MOVE.B    #5,D0
    TRAP      #15
    
    CMP.B     #'Y',D1
    BEQ       CONTINUE_YES
    CMP.B     #'y',D1
    BEQ       CONTINUE_YES
    CMP.B     #'N',D1    
    BEQ       CONTINUE_NO
    CMP.B     #'n',D1    
    BEQ       CONTINUE_NO

    BRA       CONTINUE_INVALID
    
CONTINUE_YES:
    MOVE.B    #0,D7
    BRA       ADDR
    
CONTINUE_NO:
    BSR       PRINT_CR
    LEA       THANKS_MSG,A1         ; DISPLAY THANK YOU MESSAGE AND TERMINATE
    MOVE.B    #13,D0
    TRAP      #15
    
    BRA EXIT
    
CONTINUE_INVALID:
    BSR       PRINT_CR
    LEA       INVALID_MSG,A1         ; DISPLAY THANK YOU MESSAGE AND TERMINATE
    MOVE.B    #13,D0
    TRAP      #15

    BRA       PRCS_ASK_TO_RESTART
	
;;;;;;;;;;;;;;;;;;;;;;;;
;; Process BRA command for 8 bit displacement
PRCS_BRA_8:
    MOVE.W    (A1),D1
    AND.W     #$00FF,D1      ; 0000 0000 1111 1111
    ADD.W     #$1,D1         ; Add 1 for 2's compliment
    NOT.B     D1             ; flips the bits
    
    MOVE.W    A2,D4
    SUB       #2,D4          ; Subtract 2 to get correct starting address for command
    SUB.W     D1,D4
    
    LEA       tempMsg,A1
    MOVE.B    #' ',(A1)+
    MOVE.B    #'$',(A1)+
    MOVE.W    D4,D0
    MOVE.W    #8,D1    
    JSR       PRINT_REG_AS_ASCII 
        
    BRA       BRA_LOOP
    
;;;;;;;;;;;;;;;;;;;;;;;;
;; Process BRA command for 16 bit displacement
PRCS_BRA_16:
    MOVE.W    (A2)+,D1
    MOVE.W    D1,D4
    ADD.W     A2,D4
    SUB.W     #2,D4
    
    LEA       tempMsg,A1
    MOVE.B    #' ',(A1)+
    MOVE.B    #'$',(A1)+
    MOVE.W    D4,D0
    MOVE.W    #8,D1    
    JSR       PRINT_REG_AS_ASCII    
    
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;
;; Process BRA command for 32 bit displacement
PRCS_BRA_32:
    MOVE.L    (A2)+,D1    
    MOVE.W    D1,D4
    ADD.W     A2,D4
    SUB.W     #4,D4
    
    LEA       tempMsg,A1
    MOVE.B    #' ',(A1)+
    MOVE.B    #'$',(A1)+
    MOVE.W    D4,D0
    MOVE.W    #8,D1    
    JSR       PRINT_REG_AS_ASCII    
    
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;
;; Process ASL command
PRCS_ASL:
    LEA       sAsl,A1        ; address of string
    MOVE.L    #0,D3          ; no parameter printing required
    JSR       CMD_PRINT  
  
    LEA       tempCmd,A1
    MOVE.W    (A1),D0        ; Read tempCmd into D0
    AND.W     #$00C0, D0
    LSR.W     #6, D0
    CMP.W     #3, D0
    BEQ       PRCS_ASL_LSL_MS
    JMP       PRCS_ASL_LSR_I_R

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process LSL command
PRCS_LSL:
    LEA       sLsl,A1        ; address of string
    MOVE.L    #0,D3          ; no parameter printing required
    JSR       CMD_PRINT   
  
    LEA       tempCmd,A1
    MOVE.W    (A1),D0        ; Read tempCmd into D0
    AND.W     #$00C0,D0
    LSR.W     #6,D0
    CMP.W     #3,D0
    BEQ       PRCS_ASL_LSL_MS
    JMP       PRCS_ASL_LSR_I_R
  
    BRA       BRA_LOOP
  
;;;;;;;;;;;;;;;;;;;;;;;;
;; Process LSL command
PRCS_ASL_LSR_I_R:
  ;; INPUT for PRINT_SIZE
  ;; D0 - Size parameter (B=0, W=1, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D0        ; Read tempCmd into D0
    AND.W     #$00C0,D0
    LSR.W     #6,D0
    BSR       PRINT_SIZE  

    LEA       tempCmd,A1
    MOVE.W    (A1),D0        ; Read tempCmd into D0
    AND.W     #$0020,D0
    CMP.W     #0,D0  
    BEQ       PRCS_ASL_LSR_I
    MOVE.W    #0,D2          ; REG MODE: #Dn)
    JMP       PRCS_ASL_LSR_CONT
    
PRCS_ASL_LSR_I:
    MOVE.W #8, D2            ; REG MODE: Immediate value (#n)

PRCS_ASL_LSR_CONT
  ;; Print address
  ;; INPUT for PRINT_REG
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1        ; Read tempCmd into D1
    MOVE.W    D1, D0
    AND.W     #$0E00, D0
    LSR.W     #8,D0
    LSR.W     #1,D0
  
    MOVE.W    D1,D3
    AND.W     #$00C0,D3
    LSR.W     #6,D3
  
    JSR       PRINT_REG

  ;; Print separating comma between the source and destination
    JSR       PRINT_COMMA
  
  ;; Print address
  ;; INPUT for PRINT_REG
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1        ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0007,D0

    MOVE.W    #0,D2          ; Data register (Dn)
  
    MOVE.W    D1,D3
    AND.W     #$00C0,D3
    LSR.W     #6,D3
  
    JSR       PRINT_REG
 
    BRA       BRA_LOOP
  
;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process LSL command
PRCS_ASL_LSL_MS:  
  ;; check the first bit to determine the address size to read (W vs. L)  
    LEA       tempCmd,A1
    MOVE.W    (A1),D1             ; Read tempCmd into D1
    MOVE.W    D1,D3
    AND.W     #$0001,D3
    CMP.W     #$0000,D3
    BEQ       ASL_LSL_MS_SIZE_W
    MOVE.W    #2,D3               ; set the size to (L)
    BRA       ASL_LSL_MS_CONT
    
ASL_LSL_MS_SIZE_W:
    MOVE.W    #3,D3          ; set the size to (W)
ASL_LSL_MS_CONT:  
    MOVE.W    D3,D0          ; D3 is set to the correct size of the command. We will copy it to D0 for PRINT_MOVE_SIZE
  
  ;; INPUT for PRINT_MOVE_SIZE
  ;; D0 - Size parameter (B=0, W=3, L=2)
    BSR PRINT_MOVE_SIZE   

  ;; Print address
  ;; INPUT for PRINT_REG
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1        ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE.W    D1,D2
    AND.W     #$0038,D2      ; 0000 0000 0011 1000
    LSR.W     #3,D2 

    JSR       PRINT_REG
    
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;
;; Process MOVEM command for DR bit = 0
PRCS_MOVEM_DR0:
    LEA       sCR,A1
    MOVE      #14,D0
    TRAP      #15
  
    BSR       PRCS_MOVEM_LIST
  
  ;; Print separating comma between the source and destination
    BSR       PRINT_COMMA

  ;; Print source register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D0        ; Read tempCmd into D1
    AND.W     #$0007,D0      ; 0000 0000 0000 0111
  
    MOVE.W    (A1),D2 
    AND.W     #$0038,D2
    LSR.W     #3,D2
  
    MOVE.W    #3,D3
    BSR       PRINT_REG
  
    BRA       BRA_LOOP
  
;;;;;;;;;;;;;;;;;;;;;;;;
;; Process MOVEM command for DR bit =1
PRCS_MOVEM_DR1:
  ;; Print source register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D0        ; Read tempCmd into D1
    AND.W     #$0007,D0      ; 0000 0000 0000 0111
  
    MOVE.W    (A1),D2 
    AND.W     #$0038,D2      ; 0000 0000 0011 1000
    LSR.W     #3,D2
  
    MOVE.W    #3,D3
    BSR       PRINT_REG
  
  ;; Print separating comma between the source and destination
    LEA       tempMsg,A1
    MOVE.B    #',',(A1)+
    MOVE.B    #9,(A1)+
    JSR       REG_WRITE
  
    BSR       PRCS_MOVEM_LIST
  
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;
;; Process MOVEM LIST  
PRCS_MOVEM_LIST:
;; D0 -- Counter 
;; D1 -- Command
;; D2 -- 
;; D3 -- 
    LEA       tempMsg,A1
    MOVE.W    (A2)+,D1       ; Read the next two bytes of the MOVEM command
    MOVE.W    D1,D2          ; Save copy of the machine code in D2
    MOVE.W    #$0001,D3
  
LIST_LOOP:
    MOVE.W    D1,D2
    AND.W     D3,D2
    CMP.W     #$8000,D2
    BEQ       LIST_A7

    CMP.W     #$4000,D2
    BEQ       LIST_A6

    CMP.W     #$2000,D2
    BEQ       LIST_A5
  
    CMP.W     #$1000,D2
    BEQ       LIST_A4
  
    CMP.W     #$0800,D2
    BEQ       LIST_A3
  
    CMP.W     #$0400,D2
    BEQ       LIST_A2
  
    CMP.W     #$0200,D2
    BEQ       LIST_A1
  
    CMP.W     #$0100,D2
    BEQ       LIST_A0
  
    CMP.W     #$0080,D2
    BEQ       LIST_D7
  
    CMP.W     #$0040,D2
    BEQ       LIST_D6
  
    CMP.W     #$0020,D2
    BEQ       LIST_D5
  
    CMP.W     #$0010,D2
    BEQ       LIST_D4
  
    CMP.W     #$0008,D2
    BEQ       LIST_D3
  
    CMP.W     #$0004,D2
    BEQ       LIST_D2
  
    CMP.W     #$0002,D2
    BEQ       LIST_D1
  
    CMP.W     #$0001,D2
    BEQ       LIST_D0
  
    BRA       LIST_SKIP
    
LIST_A7:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'7',(A1)+   
    BRA       LIST_CONT 
   
LIST_A6:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'6',(A1)+   
    BRA       LIST_CONT

LIST_A5:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'5',(A1)+ 
    BRA       LIST_CONT
   
LIST_A4:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'4',(A1)+ 
    BRA       LIST_CONT
   
LIST_A3:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'3',(A1)+ 
    BRA       LIST_CONT
   
LIST_A2:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'2',(A1)+ 
    BRA       LIST_CONT

LIST_A1:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'1',(A1)+ 
    BRA       LIST_CONT
   
LIST_A0:
    MOVE.B    #'A',(A1)+   
    MOVE.B    #'0',(A1)+ 
    BRA       LIST_CONT 
   
LIST_D7:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'7',(A1)+ 
    BRA       LIST_CONT
   
LIST_D6:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'6',(A1)+ 
    BRA       LIST_CONT

LIST_D5:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'5',(A1)+ 
    BRA       LIST_CONT
   
LIST_D4:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'4',(A1)+ 
    BRA       LIST_CONT
   
LIST_D3:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'3',(A1)+ 
    BRA       LIST_CONT
   
LIST_D2:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'2',(A1)+ 
    BRA       LIST_CONT

LIST_D1:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'1',(A1)+ 
    BRA       LIST_CONT
   
LIST_D0:
    MOVE.B    #'D',(A1)+   
    MOVE.B    #'0',(A1)+ 
    BRA       LIST_CONT
   
LIST_CONT:
    MOVE.B    #'/',(A1)+
    
LIST_SKIP:   
    LSL.W     #1,D3          ; Shift comparison bit to the right
    CMP.W     #0,D3          ; Restart loop until counter equals 0
    BNE       LIST_LOOP   
    MOVE.B    D0,-(A1)
    JSR       REG_WRITE
    RTS 
  
;;;;;;;;;;;;;;;;;;;;;;;;
;; Process MULS.W command
PRCS_MULS_W:
  ;; put printing code here for MULS.W
    LEA       sMulsW,A1      ; address of string
    MOVE.L    #0,D3          ; no parameter printing required
    JSR       CMD_PRINT  
  
  ;; Print the source/destination paramter
    JSR       PRCS_MULS_OR_DIVU_REG
  
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;
;; Process AND command  
PRCS_AND:  
    LEA       sAnd,A1        ; address of string 
    MOVE.L    #0,D3          ; no parameter printing required 
    BSR       CMD_PRINT      ; Print AND
  
  ;; INPUT for PRINT_SIZE
  ;; D0 - Size parameter (B=0, W=1, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D0        ; Read tempCmd into D0
    AND.W     #$00C0,D0
    LSR.W     #6,D0
    BSR       PRINT_SIZE   
  
  ;; Print the source and destination parameters
    JSR       PRCS_OPMODE_REG
  
    BRA       BRA_LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utility command for the program      
INPUT:
    CLR.L     D0
    CLR.L     D2             ; Result register

HEX:
    CMP       #0,D1          ; D1 contains the number of character read from user.
    BEQ       CMD_RTS        ; Once the count is zero, we will exit the loop
    MOVE.B    (A1)+,D0       ; Read single byte from A1
    CMP       #'9',D0
    BLE       NUMBER
    SUB.B     #7,D0          ;
NUMBER:    
    SUB.B     #48,D0         ; get number value    
    LSL.L     #4,D2          ; Shift 4 bit to accomodate new input
    ADD.B     D0,D2
    SUB.B     #1,D1          ; Decrement loop counter 
    BRA       HEX
    
CMD_RTS:    
    RTS                      ; return 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A1 - contains the message to write
;; D2 - Two byte command data
;; D3 - Boolean flag (0 or 1) indicating if command required parameter printing
;; D4 - Size of parameter string to zero pad it    
CMD_PRINT:
    MOVE.W    #14,D0         ; task #14 (display null string)
    TRAP      #15  

    ; Check if printing parameter opiton was set, if so, print it otherwise print BR and return
    CMP       #0,D3
    BEQ       CMD_RTS

    MOVE.L    D2,D0
    MOVE.L    D4,D1
    
    JSR       PRINT_REG_AS_ASCII
    RTS
    
PRINT_CR:
    LEA       sCR,A1
    MOVE      #13,D0         ; task #14 (display null string)
    TRAP      #15          
    RTS

PRINT_COMMA:
    LEA       sComma,A1
    MOVE      #14,D0         ; task #14 (display null string)
    TRAP      #15          
    RTS
    
PRINT_PADDING:
    CMP       #0,D4          ; check the padding counter if padding is needed
    BEQ       CMD_RTS
    SUB       #1,D4          ; decrement padding counter
        
    CMP       #0,D1
    BEQ       PAD_ZERO
    LSR       #4,D1
    
    BRA       PRINT_PADDING    

PAD_ZERO:
    LEA       sZero,A1
    MOVE.W    #14,D0         ; task #14 (display null string)
    TRAP      #15  
    BRA       PRINT_PADDING

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Print the Size of command .B, .W, .L
;; D0 - The value of the size command    
PRINT_MOVE_SIZE:
    LEA       tempMsg,A1     ; load the tempMsg variable so we can write the size msg
    MOVE.B    #'.',(A1)+
    CMP.B     #1,D0
    BEQ       SIZE_B
    CMP.B     #2,D0
    BEQ       SIZE_L
    CMP.B     #3,D0
    BEQ       SIZE_W
    RTS
;;*****************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Print the Size of command .B, .W, .L
;; D0 - The value of the size command    
PRINT_SIZE:
    LEA       tempMsg,A1     ; load the tempMsg variable so we can write the size msg
    MOVE.B    #'.',(A1)+
    CMP.B     #0,D0
    BEQ       SIZE_B
    CMP.B     #1,D0
    BEQ       SIZE_W
    CMP.B     #2,D0
    BEQ       SIZE_L
    RTS
    
SIZE_B:
    MOVE.B    #'B',(A1)+
    BRA       SIZE_WRITE
   
SIZE_W:
    MOVE.B    #'W',(A1)+
    BRA       SIZE_WRITE
    
SIZE_L:
    MOVE.B    #'L',(A1)+
    BRA       SIZE_WRITE
      
SIZE_WRITE:
    MOVE.B    #9,(A1)+       ;; Add TAB after the size command   
    MOVE.B    #0,(A1)+       ;; Terminate the message
    LEA       tempMsg,A1     ;; Load the tempMsg address in A1
    MOVE.B    #14,D0    
    TRAP      #15    
    RTS
;;*****************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Print the Size of command D0 - D7
;; D0 - parameter of the data register
;; D2 - Mode parameter (Dn, An, (An), etc)  
;; D3 - Size parameter (B=0, W=3, L=2)

PRINT_REG:
    MOVE.W    #0, D5

    LEA       tempMsg,A1     ; load the tempMsg variable so we can write the size msg
    MOVE.B    #' ',(A1)+
    CMP.W     #0,D2
    BEQ       REG_Dn
    CMP.W     #1,D2
    BEQ       REG_An
    CMP.W     #2,D2
    BEQ       REG_PAn
    CMP.W     #3,D2
    BEQ       REG_PAnPlus
    CMP.W     #4,D2
    BEQ       REG_MinusPAn
    CMP.W     #7,D2
    BEQ       REG_Addr
    CMP.W     #8,D2
    BEQ       REG_Immediate
    
REG_Dn:    
    MOVE.B    #'D',(A1)+
    BSR       REG_NUMBER
    BRA       REG_WRITE
    
REG_An:    
    MOVE.B    #'A',(A1)+
    BSR       REG_NUMBER
    BRA       REG_WRITE
    
REG_PAn:
    MOVE.B    #'(',(A1)+    
    MOVE.B    #'A',(A1)+
    BSR       REG_NUMBER
    MOVE.B    #')',(A1)+
    BRA       REG_WRITE
    
REG_PAnPlus:
    MOVE.B    #'(',(A1)+    
    MOVE.B    #'A',(A1)+
    BSR       REG_NUMBER
    MOVE.B    #')',(A1)+
    MOVE.B    #'+',(A1)+
    BRA       REG_WRITE
    
REG_MinusPAn:
    MOVE.B    #'-',(A1)+
    MOVE.B    #'(',(A1)+    
    MOVE.B    #'A',(A1)+
    BSR       REG_NUMBER
    MOVE.B    #')',(A1)+
    BRA       REG_WRITE
    
REG_Immediate:  
    MOVE.B    #'#',(A1)+
    BSR       REG_NUMBER
    BRA       REG_WRITE
    
REG_Addr:
    MOVE.W    D0,D4
    AND.W     #$0004, D4
    LSR.W     #2,D4
    CMP.W     #1,D4
    BNE       REG_NO_POUND
    MOVE.B    #'#',(A1)+
    SUB.W     #8,D5
REG_NO_POUND
    ADD.W     #8,D5
    MOVE.B    #'$',(A1)+    
    MOVE.B    #0,(A1)+
    LEA       tempMsg,A1
    CLR.L     D2             ; parameter for address data
    CMP.W     #2,D3
    BNE       REG_Addr_Not_L
    MOVE.W    (A2)+, D2     ; Read two bytes in D2
    MOVE.L    #4,D4
    
REG_Addr_Not_L:
    LSL.L     #8,D2
    LSL.L     #8,D2    
    MOVE.W    (A2)+,D2   ; Read two bytes in D2
    ADD.B     #4,D4       ; Number of bytes to pad when printing the address
    
    MOVE.L    #1,D3        ; parameter printing required
    MOVE.L    D5,D4        ; We are setting to zero so we DO NOT PAD
    
  ;; INPUT for CMD_PRINT
  ;; A1 - contains the message to write
  ;; D2 - Two byte command data
  ;; D3 - Boolean flag (0 or 1) indicating if command required parameter printing
  ;; D4 - Size of parameter string to zero pad it    
    BSR       CMD_PRINT   
    RTS

REG_WRITE:
    MOVE.B    #0,(A1)+
    LEA       tempMsg,A1
    MOVE.B    #14,D0    
    TRAP      #15    
    RTS
    
REG_NUMBER:    
    ADD.B     #'0',D0
    MOVE.B    D0,(A1)+
    RTS
    
;;***************************************** 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Print the paramters for add and sub registers
PRCS_MULS_OR_DIVU_REG:
  ;; Print source register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Reg number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1        ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE.W    D1,D2
    AND.W     #$0038,D2
    LSR.W     #3,D2

    MOVE.W    #3,D3
    BSR       PRINT_REG

  ;; Print separating comma between the source and destination
    BSR       PRINT_COMMA
  
  ;; Print destination register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Size parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1        ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0E00,D0
    LSR.W     #8,D0
    LSR.W     #1,D0
  
    MOVE.W    #0,D2
    MOVE.W    #3,D3
    BSR       PRINT_REG        

    RTS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Print the paramters for add and sub registers
PRCS_OPMODE_REG:
  ;; Print source register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Reg number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd,A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0100,D0
    CMP.W     #0,D0
    BNE       ADD_SRC_SWAP
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE.W    D1,D2
    AND.W     #$0038,D2
    LSR.W     #3,D2  
    BRA       ADD_SRC_CONT
    
ADD_SRC_SWAP:
    MOVE.W    D1,D0
    AND.W     #$0E00,D0
    LSR.W     #8,D0
    LSR.W     #1,D0

    MOVE.W    #0,D2
    
ADD_SRC_CONT:
    MOVE.W    #0,D3
  
    BSR       PRINT_REG    
  
  ;; Print separating comma between the source and destination
    BSR       PRINT_COMMA
  
  ;; Print destination register/address
  ;; INPUT for PRINT_REG
  ;; D0 - Reg number parameter (0 - 7)
  ;; D2 - Mode parameter (Dn, An, (An), etc)  
  ;; D3 - Size parameter (B=0, W=3, L=2)
    LEA       tempCmd, A1
    MOVE.W    (A1),D1         ; Read tempCmd into D1
    MOVE.W    D1,D0
    AND.W     #$0100,D0
    CMP.W     #0,D0
    BNE       ADD_DEST_SWAP
    MOVE.W    D1,D0
    AND.W     #$0E00,D0
    LSR.W     #8,D0
    LSR.W     #1,D0
  
    MOVE.W    #0,D2
    BRA       ADD_DEST_CONT
    
ADD_DEST_SWAP:
    MOVE.W    D1,D0
    AND.W     #$0007,D0
  
    MOVE.W    D1,D2
    AND.W     #$0038,D2
    LSR.W     #3,D2
ADD_DEST_CONT:  
    MOVE      #0,D3
    BSR       PRINT_REG    

    RTS
;;*****************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Validate the opcode for both add and sub
VALIDATE_ADD_OR_SUB_OPCODE:
    AND.W     #$01C0,D0
    LSR.W     #6,D0
    CMP       #3,D0
    BEQ       __UNKNOWN
    CMP       #7,D0
    BEQ       __UNKNOWN
    RTS

;;***************************************** 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Print data in D0 as ascii value
;; A1 - 
;; D0 - parameter of the data register
;; D1 - PADDING SIZE
PRINT_REG_AS_ASCII:
    MOVE.W    #8,D3
    
STR_PAD_LOOP:
    MOVE.L    D0,D2
    AND.L     #$F0000000,D2
    CMP.L     #0,D2
    BNE       STR_PAD_LOOP_DONE
    CMP.W     #1,D3
    BEQ       STR_PAD_LOOP_DONE
    SUB       #1,D3
    LSL.L     #4,D0
    BRA       STR_PAD_LOOP
    
STR_PAD_LOOP_DONE:
    CMP.W     D1,D3
    BGE       STR_DATA_LOOP
    ADD       #1,D3
    LSR.L     #4,D0
    BRA       STR_PAD_LOOP_DONE
    
STR_DATA_LOOP:
    CMP.W     #0,D3
    BEQ       STR_DONE
    SUB       #1,D3
    MOVE.L    D0,D2
    LSL.L     #4,D0
    AND.L     #$F0000000,D2
    ROL.L     #4,D2
    CMP.B     #10,D2
    BLT       STR_NUM
    ADD.B     #55,D2
    BRA       STR_CONT
    
STR_NUM:
    ADD       #'0',D2
    
STR_CONT:    
    MOVE.B    D2,(A1)+
    BRA       STR_DATA_LOOP
    
STR_DONE:
    MOVE.B    #0,(A1)+
    LEA       tempMsg,A1
    
    MOVE.B    #14,D0
    TRAP      #15

    RTS
    
EXIT:
    SIMHALT                  ; halt simulator

* Variables and constants listed here
WEL_MSG       DC.B      'Welcome to our CSS 422 EASy68K Disassembler!',CR,LF,0
TEAM_MSG      DC.B      'Team Sushi: Shane Clark, Ahmad Yousif, Simon Arsonsky, HsinYu Chin',CR,LF,CR,LF,0
START_ADDR    DC.B      CR,LF,'To begin, please enter a starting address in hexadecimal: ',0
END_ADDR      DC.B      'Now enter an ending address in hexadecimal: ',0
ERROR_MSG     DC.B      'Address is invalid or out of range.',CR,LF,CR,LF,0
CONTINUE_MSG  DC.B      CR,LF,CR,LF,'Press any key to continue. ',0
RESTART_MSG   DC.B      CR,LF,'Do you want to restart the program (Y/N)? ',0
INVALID_MSG   DC.B      'Invalid response entered. Only use [Y] or [N]. ',0
THANKS_MSG    DC.B      'Thank you for using the program.',0
ADDR_RESPONSE DC.W      $9900

sNop          DC.B      TAB,'NOP ',0
sMove         DC.B      TAB,'MOVE',0
sMovem        DC.B      TAB,'MOVEM',0
sAdd          DC.B      TAB,'ADD',0
sSub          DC.B      TAB,'SUB',0
sDivuW        DC.B      TAB,'DIVU.W',TAB,0
sMulsW        DC.B      TAB,'MULS.W',TAB,0
sAnd          DC.B      TAB,'AND',0
sJsr          DC.B      TAB,'JSR',TAB,0
sRts          DC.B      TAB,'RTS ',0
sNot          DC.B      TAB,'NOT',0
sLsl          DC.B      TAB,'LSL',0
sAsl          DC.B      TAB,'ASL',0
sLea          DC.B      TAB,'LEA',TAB,0
sBra          DC.B      TAB,'BRA',TAB,0
sBcc          DC.B      TAB,'BCC',TAB,0
sBeq          DC.B      TAB,'BEQ',TAB,0
sBgt          DC.B      TAB,'BGT',TAB,0
sBle          DC.B      TAB,'BLE',TAB,0
sUnknown      DC.B      TAB,'DATA',TAB,0

tempMsg       DS.B      50        ; variable to save temporary messages for printing
tempCmd       DS.B      2         ; variable to save the 16 bit command
sCR           DC.B      ' ',0
sZero         DC.B      '0',0
sComma        DC.B      ',',0

    END       START               ; last line of source












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
