.mode std
.stack 1
.text
addi r16,r24,#5
call label1
slli r2,r3,#4
nop
j end
label1:
ori r1,r2,#255
sw 1024(r24),r31
call label2
andi r5,r1,#1345
lw r31,1024(r24)
ret
label2:
subi r2,r24,#10
sw 1028(r24),r31
call label3
xori r3,r24,#255
lw r31,1028(r24)
ret
label3:
srai r1,r2,#5
sw 1032(r24),r31
call label4
snei r13,r15,#0
lw r31,1032(r24)
ret
label4:
slli r4,r5,#3
nop
ret
end:
nop
