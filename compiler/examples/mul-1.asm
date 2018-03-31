.mode dbg
.stack 1
.text
cvti2f r6,r1
cvti2f r7,r2
movi2fp f0,r6
movi2fp f1,r7
multf f2,f0,f1
cvtf2i f4,f2
;cvtf2i f5,f3
