.mode std
.ecp full
.stack 1
.r0
subi r0,r0,#1
rfe
.text
ori r0,r24,#32767
sll r0,r0,#15
ori r0,r0,#32767
sll r0,r0,#1
ori r0,r0,#1
addi r1,r0,#4
