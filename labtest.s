.data
instruction:
    .word 0x23bdfffc
    .word 0xafbe0000
    .word 0x001df020
    .word 0x23bdfffc
    .word 0xafdffffc
    .word 0x00005020
    .word 0x0c10001b
    .word 0x0c10001b
    .word 0x0c10001b
    .word 0x01005020
    .word 0x214a0001
    .word 0x03007820
    .word 0x23290001
    .word 0x8fdffffc
    .word 0x23bd0004
    .word 0x8fbe0000
    .word 0x23bd0004
    .word 0x03e00008
    .word 0x20080001
    .word 0x20090002
    .word 0x200a0003
    .word 0x200b0004
    .word 0x03e00008
    .word 0xffffffff

#this array is 10 words: 1 word for each function call
#fix this, it is the instructions not the registers
.align 4
visited:
    .space 4000    #visited = []

.align 4
allLiveRegs:
    .space 400   #allLiveRegs = []

#this is a word
.align 4
liveRegs:
    .word 0     #liveRegs = word

#deadstack is not static, do not use
.align 4
deadStack:
    .space 400   #unknown

noDeadCheck:
    .word 1,2,3,4,5,6,7,40,41,43,0

twoLiveCheck:
    .word 4,5,40,41,43,0

branchCheck:
    .word 1,4,5,6,7,0
returnInstruction:
#jr $ra
    .word 0x03e00008

.text

findLive:    
    addi $sp $sp -28    #increment $sp for stack space
    sw $ra 0($sp)       #store $ra into stack
    sw $s0 4($sp)       #store $s0 into stack
    sw $s1 8($sp)       #store $s1 into stack
    sw $s2 12($sp)      #store $s2 into stack
    sw $s3 16($sp)      #store $s3 into stack
    sw $s4 20($sp)      #store $s4 into stack
    sw $s5 24($sp)      #store $s5 into stack

    move $s0 $a0        #beginningAddress = beginningAddressArg
    move $s1 $0         #resultIndex = 0	# for the index into allLiveRegs
    la $s2 allLiveRegs  #address of allLiveRegs
    la $s3 liveRegs     #address of liveRegs
    la $s4 deadStack    #address of deadStack
    move $s5 $a0        #currAddress = beginningAddress

    functionCheck:
        lw $t0 0($s5)               #load address of instruction
        srl $t0 $t0 26              #get opcode
        li $t1 3                    #load 0000...000011(jal opcode) into t1
        beq $t0 $t1 functionCall    #if equal goto functionCall
        lw $t0 0($s5)               #load address of instruction
        li $t1 -1                   #load 1111...111 (0xFFFFFFFF) into t1
        beq $t0 $t1 endFindLive     #if equal goto end
        addi $s5 $s5 4              #add 4 to s0(currAddress)
        j functionCheck             #goback to functionCheck

    functionCall:
        addi $s5 $s5 4      #address of instruction +4
        move $a0 $s5        #address of instruction right after the function call
        
        move $a1 $0         #deadStackIndex = 0
        jal gatherLiveRegs  #goto gatherLiveRegs
        add $t0 $s2 $s1     #address of allLiveRegs[resultIndex]
        lw $t1 0($s3)       #get liveRegs
        sw $t1 0($t0)       #allLiveRegs[resultIndex] = liveRegs
        addi $s1 $s1 4      #resultIndex ++ by 4 because of addresses
        sw $0 0($s4)        #deadStack[0] = 0
        sw $0 0($s3)         #liveRegs = 0
        #addi $s5 $s5 4      #add 4 to s5(currAddress)
        j functionCheck     #goback to functionCheck

    endFindLive:
        li $t0 -1           #t1 = -1
        add $t1 $s2 $s1     #address of allLiveRegs[resultIndex]
        sw $t0 0($t1)       #allLiveRegs[resultIndex] = -1
        move $v0 $s2        #move allLiveRegs address to v0

        lw $ra 0($sp)       #load $ra from stack
        lw $s0 4($sp)       #load $s0 from stack
        lw $s1 8($sp)       #load $s1 from stack
        lw $s2 12($sp)      #load $s2 from stack
        lw $s3 16($sp)      #load $s3 from stack
        lw $s4 20($sp)      #load $s4 from stack
        lw $s5 24($sp)      #load $s5 from stack
        addi $sp $sp 28     #decrement stack pointer
        
        jr $ra              #return to address at ra

#Arguments
#a0 - address of function call
#a1 - deadStackIndex

gatherLiveRegs:

    addi $sp $sp -28    #increment $sp for stack space
    sw $ra 0($sp)       #store $ra into stack
    sw $s0 4($sp)       #store $s0 into stack
    sw $s1 8($sp)       #store $s1 into stack
    sw $s2 12($sp)      #store $s2 into stack
    sw $s3 16($sp)      #store $s3 into stack
    sw $a0 20($sp)      #store $a0 into stack
    sw $a1 24($sp)      #store $a1 into stack

    sub $t0 $a0 $s0                 #index = address-beginningAddress
    lw $t1 0($a0)                   #load instruction from address
    move $s3 $a1                    #move deadStackIndex to s3
    la $s1 liveRegs                 #load liveRegs address
    lw $s1 0($s1)                   #load liveRegs
    la $s2 deadStack                #load deadStack address
    sll $a1 $a1 2                   #a1*4
    add $s2 $s2 $a1                 #address of deadStack[deadStackIndex]
    lw $s2 0($s2)                   #load deadStack[deadStackIndex]
    la $t2 visited                  #load visited address
    add $t2 $t2 $t0                 #address of visited[index]
    lw $t3 0($t2)                   #load visited[index]
    li $t4 1                        #t4 = 1
    beq $t3 $t4 endGatherLiveRegs   #if equal goto end
    la $t5 returnInstruction
    lw $t5 0($t5)
    beq $t1 $t5 endGatherLiveRegs
    sw $t4 0($t2)                   #visited[index] = 1
    j UpdateLiveRegs                #goto UpdateLiveRegs

    UpdateLiveRegs:
        srl $t3 $t1 26          #get opcode
        beq $t3 $0 twoRegs      #if opcode = 0 (RType opcode) goto twoRegs
        li $t4 2                #load j opcode
        beq $t3 $t4 UpdateDead  #if j goto UpdateDead
        li $t4 3                #load jal opcode
        beq $t3 $t4 UpdateDead  #if jal goto UpdateDead
        la $t5 twoLiveCheck     #load twoLiveCheck address
        lw $t4 0($t5)           #get twoLiveCheck[0]

        liveLoop:
            beq $t3 $t4 twoRegs #if beq goto twoRegs
            addi $t5 $t5 4      #address twoLiveCheck[i+1]
            lw $t4 0($t5)       #load twoLiveCheck[i+1]
            beq $t4 $0 oneReg   #if nothing in array left goto oneReg
            j liveLoop          #otherwise goto liveLoop

        twoRegs:
            srl $t3 $t1 16      #get opcode+rs+rt
            andi $t3 $t3 0x001f #get rt through mask
            li $t4 1            #t4 = 1
            sllv $t4 $t4 $t3    #t4 << register number
            and $t3 $t4 $s2     #check if register in deadStack[deadStackIndex]
            bne $t3 $0 oneReg   #if not equal 0 goto oneReg
            or $s1 $s1 $t4      #add register to liveRegs

        oneReg:
            srl $t3 $t1 21                  #get opcode+rs
            andi $t3 $t3 0x001f             #get rs through mask
            li $t4 1                        #t4 = 1
            sllv $t4 $t4 $t3                #t4 << register number
            and $t3 $t4 $s2                 #check if register in deadStack[deadStackIndex]
            bne $t3 $0 endUpdateLiveRegs    #if not equal 0 goto endUpdateLiveRegs
            or $s1 $s1 $t4                  #add register to liveRegs

        endUpdateLiveRegs:
            lui $t3 0x03ff          #top of mask
            addi $t3 $t3 0xfff0     #bottom of mask
            and $s1 $s1 $t3         #mask liveRegs to only show a0 - t9
            la $t3 liveRegs #load liveRegs address
            sw $s1 0($t3)   #load liveRegs into memory

    UpdateDead:
        srl $t3 $t1 26      #get opcode
        beq $t3 $0 rType    #if opcode = 0 (RType opcode) goto rType
        la $t5 noDeadCheck  #load noDeadCheck address
        lw $t4 0($t5)       #get noDeadCheck[0]

        deadLoop:
            beq $t3 $t4 endUpdateDead   #if beq goto endUpdateDead
            addi $t5 $t5 4              #address noDeadCheck[i+1]
            lw $t4 0($t5)               #load noDeadCheck[i+1]
            beq $t4 $0 oneDeadReg       #if nothing in array left goto oneDeadReg
            j deadLoop                  #otherwise goto deadLoop

        rType:
            srl $t3 $t1 11      #get opcode+rs+rt+rd
            andi $t3 $t3 0x001f #get rd through mask
            li $t4 1            #t4 = 1
            sllv $t4 $t4 $t3    #t4 << register number
            or $s2 $s2 $t4      #add register to liveRegs
            j endUpdateDead     #goto endUpdateDead

        oneDeadReg:
            srl $t3 $t1 16      #get opcode+rs+rt
            andi $t3 $t3 0x001f #get rt through mask
            li $t4 1            #t4 = 1
            sllv $t4 $t4 $t3    #t4 << register number
            or $s2 $s2 $t4      #add register to liveRegs

        endUpdateDead:
            la $t3 deadStack        #load address of deadStack
            add $t3 $t3 $a1         #get deadStack[deadStackIndex] address
            sw $s2 0($t3)           #save deadStack to deadStack[deadStackIndex]

    li $t4 2                #load 0000...000010(j opcode) into t1
    srl $t5 $t1 26          #get opcode of instruction
    beq $t4 $t5 jumpCall    #if equal goto jumpCall

    la $t4 branchCheck  #get branchCheck address
    lw $t6 0($t4)       #get branchCheck[0]

    branchLoop:
        beq $t5 $t6 branchCall  #if opcode is branch, goto branchCall
        addi $t4 $t4 4  #get branchCheck[i+1] address
        lw $t6 0($t4)   #get branchCheck[i+1]
        bne $t6 $0 branchLoop   #if not out of array goto branchLoop

    endBranch:
        lw $a0 20($sp)
        addi $a0 $a0 4
        lw $a1 24($sp)
        jal gatherLiveRegs
        j endGatherLiveRegs

    branchCall:
        lw $a0 20($sp)      #get address
        addi $a0 $a0 4      #PC + 4
        sll $t6 $t1 16      #get last 16 bits of instruction
        sra $t6 $t6 14      #sign extend t6 and shift right by 14, total will be shift left by 2 and signextended
        add $a0 $a0 $t6     #add t6 to PC + 4
        lw $a1 24($sp)      #get deadStackIndex
        addi $a1 $a1 1      #deadStackIndex++
        sll $t6 $a1 2       #deadStackIndex*4
        la $t7 deadStack
        add $t6 $t6 $t7
        sw $s2 0($t6)       #clone deadStack[deadStackIndex] to deadStackIndex+1
        jal gatherLiveRegs  #call gatherLiveRegs(target,deadStackIndex)
        addi $a1 $a1 -1     #deadStackIndex--
        j endBranch         #goto endBranch

    jumpCall:
        lw $a0 20($sp)      #get address of instruction
        addi $a0 $a0 4      #PC + 4
        srl $t4 $a0 28      #get the 4 most significant bits
        sll $t4 $t4 28
        sll $t5 $t1 6       #remove opcode from instruction
        srl $t5 $t5 4       #shift right by 4 so total shift is left by 2
        or $a0 $t4 $t5      #get address of target instruction
        lw $a1 24($sp)      #get deadStackIndex
        jal gatherLiveRegs  #goto gatherLiveRegs

    endGatherLiveRegs:
        la $t2 visited
        sub $t0 $a0 $s0
        add $t2 $t2 $t0
        sw $0 0($t2)    #visited[index] = 0
        
        lw $ra 0($sp)   #load $ra from stack
        lw $s0 4($sp)   #load $s0 from stack
        lw $s1 8($sp)   #load $s1 from stack
        lw $s2 12($sp)  #load $s2 from stack
        lw $s3 16($sp)
        lw $a0 20($sp)  #load $a0 from stack
        lw $a1 24($sp)  #load $a1 from stack
        addi $sp $sp 28 #increment $sp for stack
        
        jr $ra          #return to address

main:
    la $a0 instruction
    jal findLive