.mode fst
.stack 1
.text
addi r0,r24,#50
addi r1,r24,#0
cvti2f r2,r0
cvti2f r3,r1
movi2fp f0,r2
movi2fp f1,r3
multf f2,f1,f0
multf f3,f2,f2
multf f4,f2,f2
sf 1024(r24),f4
sf 1028(r24),f4
cvtf2i f5,f3
cvtf2i f6,f4
movfp2i r16,f6
movfp2i r17,f6
add r0,r17,r17
add r1,r17,r17
movfp2i r18,f6
bnez r18,label
bnez r18,label
;sw 1032(r24),r18
;sw 1036(r24),r18
label:
nop
.data
.word 255
