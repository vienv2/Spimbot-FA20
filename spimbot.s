t.data
# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

TIMER                   = 0xffff001c

REQUEST_PUZZLE          = 0xffff00d0  ## Puzzle
SUBMIT_SOLUTION         = 0xffff00d4  ## Puzzle

BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000      
TIMER_ACK               = 0xffff006c 

REQUEST_PUZZLE_INT_MASK = 0x800       ## Puzzle
REQUEST_PUZZLE_ACK      = 0xffff00d8  ## Puzzle

PICKUP                  = 0xffff00f4

artGET_NUM_KERNELS         = 0xffff2010

# Add any MMIO that you need here (see the Spimbot Documentation)

three: .float 3.0
five: .float 5.0
PI: .float 3.141592
F180: .float 180.0

### Puzzle
GRIDSIZE = 8
has_puzzle:        .word 0                         
puzzle:      .half 0:2000             
heap:        .half 0:2000

minibot_info:  
.word 0

num_kernels: .word 0:1

#### Puzzle



.text
main:
# Construct interrupt mask
	    li      $t4, 0
        or      $t4, $t4, REQUEST_PUZZLE_INT_MASK # puzzle interrupt bit
        or      $t4, $t4, TIMER_INT_MASK	  # timer interrupt bit
        or      $t4, $t4, BONK_INT_MASK	  # timer interrupt bit
        or      $t4, $t4, 1                       # global enable
	    mtc0    $t4, $12

#Fill in your code here
        # li $a0, 116;
        # li $a1, 104;
        # jal travel_to_point;
        # li $a0, 56;
        # li $a1, 170;
        # jal travel_to_point;

        jal build_silo;

infinite:
        j       infinite              # Don't remove this! If this is removed, then your code will not be graded!!!

travel_to_point:
        sub $sp, $sp, 12;
        sw $ra, 0($sp);
        sw $s0, 4($sp);
        sw $s1, 8($sp);

        move $s0, $a0;
        move $s1, $a1;

travel_to_point_loop:
        lw $t0, BOT_X;
        sub $t1, $t0, 8;
        add $t2, $t0, 8;

        blt $s0, $t1, travel_to_point_move;
        bgt $s0, $t2, travel_to_point_move;

        lw $t1, BOT_Y;
        sub $t2, $t1, 8;
        add $t3, $t1, 8;

        blt $s1, $t2, travel_to_point_move;
        blt $s1, $t3, finish_travel_to_point;

travel_to_point_move:
        lw $t0, BOT_X;
        lw $t1, BOT_Y;

        sub $a0, $s0, $t0;
        sub $a1, $s1, $t1;
        jal sb_arctan; # $v0 will have the angle we need to set the bot to
        li $t0, 1;
        sw $t0, ANGLE_CONTROL($zero);
        sw $v0, ANGLE($zero);
        li $t0, 1;
        sw $t0, VELOCITY;

        j travel_to_point_loop;

finish_travel_to_point:
        li $t0, 0;
        sw $t0, VELOCITY;

        lw $ra, 0($sp);
        lw $s0, 4($sp);
        lw $s1, 8($sp);
        add $sp, $sp, 12;
        jr $ra;

sb_arctan:
        li $v0, 0 # angle = 0;
        abs $t0, $a0 # get absolute values
        abs $t1, $a1
        ble $t1, $t0, no_TURN_90
        move $t0, $a1 
        neg $a1, $a0 
        move $a0, $t0 
        li $v0, 90
no_TURN_90:
        bgez $a0, pos_x
        add $v0, $v0, 180
pos_x:
        mtc1 $a0, $f0
        mtc1 $a1, $f1 
        cvt.s.w $f0, $f0 
        cvt.s.w $f1, $f1 
        div.s $f0, $f1, $f0 
        mul.s $f1, $f0, $f0 
        mul.s $f2, $f1, $f0 
        l.s $f3, three 
        div.s $f3, $f2, $f3 
        sub.s $f6, $f0, $f3 
        mul.s $f4, $f1, $f2 
        l.s $f5, five 
        div.s $f5, $f4, $f5 
        add.s $f6, $f6, $f5 
        l.s $f8, PI
        div.s $f6, $f6, $f8 
        l.s $f7, F180 
        mul.s $f6, $f6, $f7 
        cvt.w.s $f6, $f6
        mfc1 $t0, $f6
        add $v0, $v0, $t0 
        jr $ra

build_silo:
        la $t0, num_kernels;
        sw $t0, GET_NUM_KERNELS;
        
        lw $t0, 4($t0);
        beq $t0, 0, build_silo_end;

build_silo_loop:

        j build_silo_loop;

build_silo_end:
        jr $ra;

.kdata
chunkIH:    .space 8  #TODO: Decrease this
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
        move      $k1, $at              # Save $at
.set at
        la      $k0, chunkIH
        sw      $a0, 0($k0)             # Get some free registers
        sw      $v0, 4($k0)             # by storing them to a global variable

        mfc0    $k0, $13                # Get Cause register
        srl     $a0, $k0, 2
        and     $a0, $a0, 0xf           # ExcCode field
        bne     $a0, 0, non_intrpt

interrupt_dispatch:                     # Interrupt:
        mfc0    $k0, $13                # Get Cause register, again
        beq     $k0, 0, done            # handled all outstanding interrupts

        and     $a0, $k0, BONK_INT_MASK # is there a bonk interrupt?
        bne     $a0, 0, bonk_interrupt

        and     $a0, $k0, TIMER_INT_MASK # is there a timer interrupt?
        bne     $a0, 0, timer_interrupt

        and 	$a0, $k0, REQUEST_PUZZLE_INT_MASK
        bne 	$a0, 0, request_puzzle_interrupt

        li      $v0, PRINT_STRING       # Unhandled interrupt types
        la      $a0, unhandled_str
        syscall
        j       done

bonk_interrupt:
        sw      $0, BONK_ACK
#Fill in your code here
        j       interrupt_dispatch      # see if other interrupts are waiting

request_puzzle_interrupt:
        sw      $0, REQUEST_PUZZLE_ACK
#Fill in your code here
        j	interrupt_dispatch

timer_interrupt:
        sw      $0, TIMER_ACK
#Fill in your code here
        j   interrupt_dispatch
non_intrpt:                             # was some non-interrupt
        li      $v0, PRINT_STRING
        la      $a0, non_intrpt_str
        syscall                         # print out an error message
# fall through to done

done:
        la      $k0, chunkIH
        lw      $a0, 0($k0)             # Restore saved registers
        lw      $v0, 4($k0)

.set noat
        move    $at, $k1                # Restore $at
.set at
        eret
