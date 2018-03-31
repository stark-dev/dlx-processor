.mode dbg
.text
addui r10,r24,#1024
sw 0(r10), r4
sb 1028(r24), r2
sb 1029(r24), r2
sh 1030(r24), r4
cvti2f r5,r2
movi2fp f1,r5
sf 1032(r24), f1
nop
lb r11, 1029(r24)
lh r12, 1030(r24)
lw r13, 0(r10)
lbu r14, 1028(r0)
lhu r15, 1030(r24)
lf f2, 1032(r24)
cvtf2i f3,f2
movfp2i r6,f3
