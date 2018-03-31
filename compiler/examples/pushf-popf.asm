.mode fst
.stack 1
.text
addi r0,r24,#50
addi r1,r24,#10
cvti2f r2,r0
cvti2f r3,r1
movi2fp f0,r2
movi2fp f1,r3
pushf f1
pushf f1
multf f2,f1,f1
cvtf2i f3,f2
movfp2i r16,f3
addi r0,r16,#1
addi r1,r16,#1
popf f4
popf f4
multf f5,f4,f4
multf f6,f4,f4
cvtf2i f0,f5
cvtf2i f1,f6
nop
.data
.word 255
