.mode fst
.stack 1
.text
cvti2f r0,r1
cvti2f r2,r3
movi2fp f0,r0
movi2fp f1,r2
addf f3,f1,f0
multf f2,f1,f0
addi r2,r1,#1
slli r2,r1,#1
cvtf2i f4,f2
cvtf2i f5,f3
addi r2,r1,#1
addi r2,r1,#1
addi r2,r1,#1

nop
.data
.word 252073008
