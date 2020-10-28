.text
#visited = []
#allLiveRegs = []
#liveRegs = []
#deadStack = []
#beginningAddress = word

findLive:
#Arguments:
#$a0 - beginningAddress
    addi $sp -8     #decrement $sp
    sw $s0 0($sp)   #store $s0
    sw $s0 4($sp)   #store $s1
    move $s0 $a0    #move $s0 to $a0 -> $s0 = beginningAddress
    addi $s1 $0     #$s1 = 0 -> $s1 = resultIndex
    jal gatherLiveRegs  #goto gatherLiveRegs











    #Fix this later
    lw $s0 0($sp)   #load $s0 back
    lw $s1 0($sp)   #load $s0 back
    addi $sp 4      #increment $sp
    jr $ra          #go back to caller

gatherLiveRegs:
#Arguments:
#$a0 - address
#$a1 - deadStackIndex
    sub $t0 $a0 $s0 #$t0 = $a0-$s0
    lw $t1 0($a0)   #load instruction
    srl $
    j UpdateLiveRegs
continue:
    j UpdateDead

    UpdateLiveRegs:
        j continue
    UpdateDead: