;;*****************************************************************************
;;! \file source/vcu0/vcu0_crc_8.asm
;;!
;;! \brief  8-bit CRC that uses the polynomial 0x07
;;
;;  \date   Apr 7, 2011
;;! 
;;
;;  Group:            C2000
;;  Target Family:    F2837x
;;
;; Copyright (C) 2015 Texas Instruments Incorporated - http://www.ti.com/ 
;; ALL RIGHTS RESERVED
;;*****************************************************************************
;;$TI Release: C28x VCU Library Version v2.10.00.00 $
;;$Release Date: Mar 3, 2015 $
;;*****************************************************************************
;;
;;*****************************************************************************
;; includes
;;*****************************************************************************
;;
;;*****************************************************************************
;; global defines
;;*****************************************************************************
;; CRC Routine defines

;
;/*! ASM- function to get the 8-bit CRC
; *
; * \param ACC = The initial value of crc, in case the message has been
; *  chopped into several parts, you can use the crc8 of the previous
; *  segment as the init value for the current segment crc8 calculation
; *  until the final crc is derived.
; * \param *+XAR4 = Address of the message buffer
; * \param AR5 = Parity of the first message byte, i.e. whether its on an even
; *  or odd address
; * \param *-SP[1]/AR0 = Length of the message in bytes
; *  
; * Calculate the 8-bit CRC of a message buffer by using the VCU instructions,
; * VCRC8L_1 and VCRC8H_1
; * 
; * \return CRC result in AL
; */      
      .def _getCRC8_vcu

_getCRC8_vcu:
	  PUSH		  XAR0
	  PUSH		  XAR1
      MOVZ        AR0, *-SP[7]       ; load rxLen
      ADDB        SP, #4              ; allocate 4 words for local
      VMOV32      *-SP[2], VCRC       ; Store current CRC
      VCRCCLR    
      MOV         *-SP[4], ACC
      VMOV32      VCRC,*-SP[4]        ; VCRC = Inital value
      MOV         AL, AR5             ; check the parity       
      SBF         _CRC8_loop_prep, EQ
      VCRC8H_1    *XAR4++             ; if parity=1, calculate high byte first
      DEC         AR0            
      SBF         _CRC8done, EQ
      
_CRC8_loop_prep:      
      MOV         AL, AR0
      MOV         AH, AR0
      AND         AL, #0xFFF8         ; check to see if the length is greater than 8 bytes
      BF          _CRC8_LSB,EQ
      LSR         AL, #3              ; loop in 8 bytes
      MOV         AR1, AL
      SUB         AR1, #1
      
      .align     (2)                  ; align at 32-bit boundary to remove penalty
      RPTB        _CRC8_post, AR1  ; loop for the middle part of the packet
      VCRC8L_1   *XAR4               
      VCRC8H_1   *XAR4++ 
      VCRC8L_1   *XAR4               
      VCRC8H_1   *XAR4++ 
      VCRC8L_1   *XAR4               
      VCRC8H_1   *XAR4++ 
      VCRC8L_1   *XAR4               
      VCRC8H_1   *XAR4++ 
_CRC8_post      

      LSL         AL, #3              ; calculating remaining number of bytes
      SUB         AH, AL
      SBF         _CRC8done, EQ       ; if multiple of 8, done
	  MOV         AR0, AH
_CRC8_LSB
      VCRC8L_1    *XAR4               ; if parity=0, calculate the low byte
      DEC         AR0       
      SBF         _CRC8done, EQ
      VCRC8H_1    *XAR4++
      DEC         AR0       
      SBF         _CRC8_LSB, NEQ
_CRC8done
      VMOV32       *-SP[4], VCRC        ; Store CRC
      MOV          AL, *-SP[4]          ; return AL 
      VMOV32       VCRC, *-SP[2]        ; Restore VCRC
      SUBB         SP, #4               ; restore stack pointer
      POP		   XAR1
      POP		   XAR0
      LRETR
      
;; End of file
