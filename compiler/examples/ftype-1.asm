.mode dbg
.stack 1
.text
cvti2f r6,r2
cvti2f r7,r1
movi2fp f0,r6
movi2fp f1,r7
addf f2,f0,f1
subf f3,f0,f1
cvtf2i f4,f2
cvtf2i f5,f3
