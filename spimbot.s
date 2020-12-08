.data
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

GET_KERNEL_LOCATIONS    = 0xffff200c
GET_MINIBOT_INFO        = 0xffff2014
GET_NUM_KERNELS         = 0xffff2010
GET_PUZZLE_CNT          = 0xffff2008
SPAWN_MINIBOT           = 0xffff00dc

# Add any MMIO that you need here (see the Spimbot Documentation)
three:  .float 3.0
five:   .float 5.0
PI:     .float 3.141592
F180:   .float 180.0
rand_x: .word 1454625
rand_y: .word 9878973
rand_z: .word 5325928
rand_w: .word 124436

### Puzzle
GRIDSIZE = 8
has_puzzle:     .word 0                     
num_puzzles:    .word 0
puzzle:         .half 0:2000
heap:           .half 0:2000

minibot_info:  
.word 0
.half 0:2000

### Kernels
kernel_locations:
num_kernels:    .word 0
kernels:        .byte 0:2000

.text
main:
        # Construct interrupt mask
	li      $t4, 0
        or      $t4, $t4, REQUEST_PUZZLE_INT_MASK # puzzle interrupt bit
        or      $t4, $t4, TIMER_INT_MASK	  # timer interrupt bit
        or      $t4, $t4, BONK_INT_MASK	          # timer interrupt bit
        or      $t4, $t4, 1                       # global enable
	mtc0    $t4, $12

        sub     $sp, $sp, 24
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)     # is_on_the_way flag
        sw      $s1, 8($sp)     # is_bonking flag
        sw      $s2, 12($sp)    # is_arrived flag
        sw      $s3, 16($sp)    # target_x
        sw      $s4, 20($sp)    # target_y

        li      $s0, 1
        li      $s1, 0
        li      $s2, 0

        # Always full speed ahead
        li      $t0, 10
        sw      $t0, VELOCITY
        li      $t0, 45
        sw      $t0, ANGLE
        li      $t0, 1
        sw      $t0, ANGLE_CONTROL
        lw      $t0, TIMER
        add     $t0, $t0, 150000
        sw      $t0, TIMER

        main_loop:

        should_pickup:
                lw      $a0, BOT_X      # $a0 = x
                lw      $a1, BOT_Y      # $a1 = y
                # jal     check_if_corn           # check whether there's corn at the current tile
                # beqz    $v0, should_request     # if $v0 == true then pickup
                sw      $0, PICKUP             # request pickup

        is_arrived:
                beqz    $s0, should_turn_around
                sub     $t0, $s3, 4
                add     $t1, $s3, 4
                blt     $a0, $t0, should_turn_around
                bgt     $a0, $t0, should_turn_around
                sub     $t0, $s4, 4
                add     $t1, $t4, 4
                blt     $a1, $t0, should_turn_around
                blt     $a1, $t1, should_turn_around
                li      $s0, 0
                li      $s2, 1

        should_turn_around:
                # beqz    $s1, should_request
                beqz    $s1, should_move
                li      $s1, 0
                jal     rand_turn_around
                sw      $v0, ANGLE
                sw      $0, ANGLE_CONTROL
                lw      $t1, TIMER
                add     $t1, $t1, $v1
                sw      $t1, TIMER
                li      $t0, 10
                sw      $t0, VELOCITY
                j       main_continue

        # should_request:
        #         lw      $t0, has_puzzle         # request if has_puzzle == false
        #         bnez    $t0, should_solve
        #         # lw     $t0, num_puzzles
        #         # bge     $t0, 3, should_spawn    # skip requesting puzzle if num_puzzles >= 3
        #         la      $t0, puzzle
        #         sw      $t0, REQUEST_PUZZLE     # request puzzle
        #         j       should_spawn            # skip solving puzzle until there is a puzzle
                
        # should_solve:
        #         bnez    $s0, main_continue
        #         sw      $0, VELOCITY
        #         jal     solve_puzzle
        #         li      $t0, 10
        #         sw      $t0, VELOCITY
        #         j       main_continue

        # should_spawn:
        #         bnez    $s0, main_continue
        #         jal     check_if_spawn_bot
        #         beqz    $v0, should_move
        #         sw      $0, SPAWN_MINIBOT       # spawn basic minibot

        should_move:
                beqz    $s2, main_continue
                sw      $0, VELOCITY
                la      $t0, kernels
                sw      $t0, GET_KERNEL_LOCATIONS
                lw      $a0, BOT_X
                lw      $a1, BOT_Y
                jal     get_best_corn
                beq     $v0, -1, main_travel_randomly
                beq     $v1, -1, main_travel_randomly
                main_travel_to_point:
                        move    $s3, $v0
                        move    $s4, $v0
                        move    $a0, $v0
                        move    $a1, $v1
                        jal     travel_to_point
                        j       main_travel_set_vel
                main_travel_randomly:
                        li      $a0, 360
                        jal     rng
                        sw      $v0, ANGLE
                        sw      $0, ANGLE_CONTROL
                        li      $a0, 90000
                        jal     rng
                        lw      $t0, TIMER
                        add     $t0, $t0, $v0
                        add     $t0, $t0, 70000
                        sw      $t0, TIMER
                main_travel_set_vel:
                        li      $s0, 1
                        li      $s2, 0
                        li      $t0, 10
                        sw      $t0, VELOCITY
        
        main_continue:
                j       main_loop

        main_end:
                # Stop moving
                sw      $0, VELOCITY
                
                lw      $ra, 0($sp)
                lw      $s0, 4($sp)
                lw      $s1, 8($sp)
                lw      $s2, 12($sp)
                lw      $s3, 16($sp)
                lw      $s4, 20($sp)
                add     $sp, $sp, 24
        
        infinite:
                j       infinite

check_if_spawn_bot:
        la      $t0, minibot_info
        sw      $t0, GET_MINIBOT_INFO

        lw      $t0, 0($t0)
        bge     $t0, 3, check_if_spawn_bot_end

        la      $t0, num_kernels
        sw      $t0, GET_NUM_KERNELS
        lw      $t0, 0($t0)
        blt     $t0, 2, check_if_spawn_bot_end

        la      $t0, num_puzzles
        sw      $t0, GET_PUZZLE_CNT
        lw      $t0, 0($t0)
        blt     $t0, 1, check_if_spawn_bot_end

        li      $t0, 0
        sw      $t0, SPAWN_MINIBOT

        check_if_spawn_bot_end:
        jr      $ra

travel_to_point:
        sub     $sp, $sp, 12
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)

        move    $s0, $a0
        move    $s1, $a1

        # travel_to_point_loop:
        #         lw      $t0, BOT_X
        #         sub     $t1, $t0, 8
        #         add     $t2, $t0, 8

        #         blt     $s0, $t1, travel_to_point_move
        #         bgt     $s0, $t2, travel_to_point_move

        #         lw      $t1, BOT_Y
        #         sub     $t2, $t1, 8
        #         add     $t3, $t1, 8

        #         blt     $s1, $t2, travel_to_point_move
        #         blt     $s1, $t3, finish_travel_to_point

        travel_to_point_move:
                lw      $t0, BOT_X
                lw      $t1, BOT_Y
                sub     $a0, $s0, $t0
                sub     $a1, $s1, $t1
                jal     sb_arctan # $v0 will have the angle we need to set the bot to
                arctan_pos_x:
                blt     $a0, 0, arctan_neg_x_pos_y
                sub     $v0, $0, $v0
                sw      $v0, ANGLE
                j       finish_travel_to_point
                arctan_neg_x_pos_y:
                blt     $a1, 0, arctan_neg_x_neg_y
                add     $v0, $v0, 180
                sub     $v0, $0, $v0
                sw      $v0, ANGLE
                j       finish_travel_to_point
                arctan_neg_x_neg_y:
                sub     $v0, $v0, 180
                sub     $v0, $0, $v0
                sw      $v0, ANGLE
                j       finish_travel_to_point

        finish_travel_to_point:
                li      $t0, 1
                sw      $t0, ANGLE_CONTROL
                lw      $ra, 0($sp)
                lw      $s0, 4($sp)
                lw      $s1, 8($sp)
                add     $sp, $sp, 12
                jr      $ra

check_if_corn:
        # $a0 = x, $a1 = y
        mul     $t0, $a1 400            # y * 400
        add     $t0, $t0, $a0           # x + y * 400
        lbu     $t0, kernels($t0)       # int num_k = k[y][x] = k[min_x + min_y * 400]
        li      $v0, 1                  # bool should_pickup = true
        bnez    $v0, should_pickup_end  # if (num_k == 0)
        move    $v0, $0                 # should_pickup = false
        should_pickup_end:
        jr      $ra                     # return should_pickup

solve_puzzle:
        sub     $sp, $sp, 4
        sw      $ra, 0($sp)

        la      $a0, puzzle
        la      $a1, heap
        jal     slow_solve_dominosa

        la      $t0, heap
        sw      $t0, SUBMIT_SOLUTION

        li      $t0, 0
        sw      $t0, has_puzzle
        la      $t0, puzzle
        sw      $t0, REQUEST_PUZZLE        

        lw      $ra, 0($sp)
        add     $sp, $sp, 4
        jr      $ra

rand_turn_around:
        # a0 = direction
        sub     $sp, $sp, 8
        sw      $ra, 0($sp)    
        li      $a0, 90
        jal     rng             # int rand_angle = rng(90)
        add     $v0, $v0, 135   # rand_angle + 135
        sw      $v0, 4($sp)     # save rand_angle
        li      $a0, 90000
        jal     rng
        add     $v0, $v0, 70000
        move    $v1, $v0
        lw      $ra, 0($sp)
        lw      $v0, 4($sp)
        add     $sp, $sp, 8
        jr      $ra
        
rng:
        lw      $t0, rand_x
        lw      $t1, rand_y
        lw      $t2, rand_z
        lw      $t3, rand_w
        sll     $t4, $t0, 11    # x << 11
        xor     $t4, $t0, $t4   # t = x ^ (x << 11)
        sw      $t1, rand_x     # x = y
        sw      $t2, rand_y     # y = z
        sw      $t3, rand_z     # z = w
        srl     $t0, $t4, 8     # t >> 8
        xor     $t0, $t4, $t5   # t ^ (t >> 8)
        srl     $t1, $t3, 19    # w >> 19
        xor     $t1, $t3, $t1   # w ^ (w >> 19)
        xor     $t0, $t1, $t0   # w ^ (w >> 19) ^ (t ^ (t >> 8))
        sw      $t0, rand_w     # w = w ^ (w >> 19) ^ (t ^ (t >> 8))
        div     $t0, $a0        # w % upper_bound
        mfhi    $v0             # return rand() < upper_bound
        jr      $ra

get_best_corn:
        # $a0 = x, $a1 = y
        li      $t0, 8
        div     $a0, $t0
        mflo    $a0
        div     $a1, $t0   
        mflo    $a1
        sub     $t0, $a0, 5    # int min_x = x - 5
        move    $a0, $t0
        sub     $t1, $a1, 5    # int min_y = y - 5
        add     $t2, $a0, 5    # int max_x = x + 5
        add     $t3, $a1, 5    # int max_y = y + 5
        move    $t4, $0         # int best_corn = 0

        move    $v0, $0         # x = -1
        move    $v1, $0         # y = -1

        if_edge_min_x:
                bgez    $t0, if_edge_min_y      # if (min_x < 0)
                move    $t0, $0                 # min_x = 0
        if_edge_min_y:
                bgez    $t1, if_edge_max_x      # if (min_y < 0)
                move    $t1, $0                 # min_y = 0
        if_edge_max_x:
                ble     $t2, 39, if_edge_max_y # if (max_x > 39)
                li      $t2, 39                # min_x = 39
        if_edge_max_y:
                ble     $t3, 39, best_corn_outer       # if (max_y > 39)
                li      $t3, 39                        # max_y = 39

        best_corn_outer:
                bge     $t1, $t3, best_corn_end # while (min_y < max_y)
                # {
                move    $t0, $a0
                best_corn_inner:
                        bge     $t0, $t2, best_corn_outer_continue # while (min_x < max_x)
                        # {
                        mul     $t5, $t1, 40            # min_y * 40
                        add     $t5, $t5, $t0           # min_x + min_y * 40
                        add     $t5, $t5, 4
                        lbu     $t5, kernels($t5)       # int curr_k = k[min_y][min_x] = k[min_x + min_y * 40]
                        if_better_corn:
                                ble     $t5, $t4, best_corn_inner_continue # if (curr_k > best_corn)
                                # {
                                move    $t4, $t5        # best_corn = curr_k
                                mul     $v0, $t0, 8
                                add     $v0, $t0, 4     # x = min_x
                                mul     $v1, $t1, 8
                                add     $v1, $v1, 4     # y = min_y
                                j       best_corn_end
                                # }
                        # }
                best_corn_inner_continue:
                        add     $t0, $t0, 1     
                        j       best_corn_inner
                # }
        best_corn_outer_continue:
                add     $t1, $t1, 1     
                j       best_corn_outer

        best_corn_end:
        jr      $ra

euclidean_dist:
        mul     $a0, $a0, $a0 # x^2
        mul     $a1, $a1, $a1 # y^2
        add     $v0, $a0, $a1 # x^2 + y^2
        mtc1    $v0, $f0
        cvt.s.w $f0, $f0 # float(x^2 + y^2)
        sqrt.s  $f0, $f0 # sqrt(x^2 + y^2)
        cvt.w.s $f0, $f0 # int(sqrt(...))
        mfc1    $v0, $f0
        jr      $ra

sb_arctan:
        li      $v0, 0  # angle = 0
        abs     $t0, $a0 # get absolute values
        abs     $t1, $a1
        ble     $t1, $t0, no_TURN_90
        move    $t0, $a1 
        neg     $a1, $a0 
        move    $a0, $t0 
        li      $v0, 90

no_TURN_90:
        bgez    $a0, pos_x
        add     $v0, $v0, 180

pos_x:
        mtc1    $a0, $f0
        mtc1    $a1, $f1 
        cvt.s.w $f0, $f0 
        cvt.s.w $f1, $f1 
        div.s   $f0, $f1, $f0 
        mul.s   $f1, $f0, $f0 
        mul.s   $f2, $f1, $f0 
        l.s     $f3, three 
        div.s   $f3, $f2, $f3 
        sub.s   $f6, $f0, $f3 
        mul.s   $f4, $f1, $f2 
        l.s     $f5, five 
        div.s   $f5, $f4, $f5 
        add.s   $f6, $f6, $f5 
        l.s     $f8, PI
        div.s   $f6, $f6, $f8 
        l.s     $f7, F180 
        mul.s   $f6, $f6, $f7 
        cvt.w.s $f6, $f6
        mfc1    $t0, $f6
        add     $v0, $v0, $t0 
        jr      $ra

# The contents of this file are not graded, it exists purely as a reference solution that you can use


# #define MAX_GRIDSIZE 16
# #define MAX_MAXDOTS 15

# /*** begin of the solution to the puzzle ***/

# // encode each domino as an int
# int encode_domino(unsigned char dots1, unsigned char dots2, int max_dots) {
#     return dots1 < dots2 ? dots1 * max_dots + dots2 + 1 : dots2 * max_dots + dots1 + 1
# }
encode_domino:
        bge     $a0, $a1, encode_domino_greater_row

        mul     $v0, $a0, $a2           # col * max_dots
        add     $v0, $v0, $a1           # col * max_dots + row
        add     $v0, $v0, 1             # col * max_dots + row + 1
        j       encode_domino_end
encode_domino_greater_row:
        mul     $v0, $a1, $a2           # row * max_dots
        add     $v0, $v0, $a0           # row * max_dots + col
        add     $v0, $v0, 1             # col * max_dots + row + 1
encode_domino_end:
        jr      $ra

# -------------------------------------------------------------------------
next:
        # $a0 = row
        # $a1 = col
        # $a2 = num_cols
        # $v0 = next_row
        # $v1 = next_col

        #     int next_row = ((col == num_cols - 1) ? row + 1 : row)
        move    $v0, $a0
        sub     $t0, $a2, 1
        bne     $a1, $t0, next_col
        add     $v0, $v0, 1
next_col:
        #     int next_col = (col + 1) % num_cols
        add     $t1, $a1, 1
        rem     $v1, $t1, $a2

        jr      $ra




# // main solve function, recurse using backtrack
# // puzzle is the puzzle question struct
# // solution is an array that the function will fill the answer in
# // row, col are the current location
# // dominos_used is a helper array of booleans (represented by a char)
# //   that shows which dominos have been used at this stage of the search
# //   use encode_domino() for indexing
# int solve(dominosa_question* puzzle, 
#           unsigned char* solution,
#           int row,
#           int col) {
#
#     int num_rows = puzzle->num_rows
#     int num_cols = puzzle->num_cols
#     int max_dots = puzzle->max_dots
#     int next_row = ((col == num_cols - 1) ? row + 1 : row)
#     int next_col = (col + 1) % num_cols
#     unsigned char* dominos_used = puzzle->dominos_used
#
#     if (row >= num_rows || col >= num_cols) { return 1 }
#     if (solution[row * num_cols + col] != 0) { 
#         return solve(puzzle, solution, next_row, next_col) 
#     }
#
#     unsigned char curr_dots = puzzle->board[row * num_cols + col]
#
#     if (row < num_rows - 1 && solution[(row + 1) * num_cols + col] == 0) {
#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[(row + 1) * num_cols + col],
#                                         max_dots)
#
#         if (dominos_used[domino_code] == 0) {
#             dominos_used[domino_code] = 1
#             solution[row * num_cols + col] = domino_code
#             solution[(row + 1) * num_cols + col] = domino_code
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1
#             }
#             dominos_used[domino_code] = 0
#             solution[row * num_cols + col] = 0
#             solution[(row + 1) * num_cols + col] = 0
#         }
#     }
#     if (col < num_cols - 1 && solution[row * num_cols + (col + 1)] == 0) {
#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[row * num_cols + (col + 1)],
#                                         max_dots)
#         if (dominos_used[domino_code] == 0) {
#             dominos_used[domino_code] = 1
#             solution[row * num_cols + col] = domino_code
#             solution[row * num_cols + (col + 1)] = domino_code
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1
#             }
#             dominos_used[domino_code] = 0
#             solution[row * num_cols + col] = 0
#             solution[row * num_cols + (col + 1)] = 0
#         }
#     }
#     return 0
# }
solve:
        sub     $sp, $sp, 80
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)
        
        move    $s0, $a0                # puzzle
        move    $s1, $a1                # solution
        move    $s2, $a2                # row
        move    $s3, $a3                # col

#     int num_rows = puzzle->num_rows
#     int num_cols = puzzle->num_cols
#     int max_dots = puzzle->max_dots
#     unsigned char* dominos_used = puzzle->dominos_used
        lw      $s4, 0($s0)             # puzzle->num_rows
        lw      $s5, 4($s0)             # puzzle->num_cols
        lw      $s6, 8($s0)             # puzzle->max_dots
        la      $s7, 268($s0)           # puzzle->dominos_used

# Compute:
# - next_row (Done below)
# - next_col (Done below)
        mul     $t0, $s2, $s5
        add     $t0, $t0, $s3           # row * num_cols + col
        add     $t1, $s2, 1
        mul     $t1, $t1, $s5
        add     $t1, $t1, $s3           # (row + 1) * num_cols + col
        mul     $t2, $s2, $s5
        add     $t2, $t2, $s3
        add     $t2, $t2, 1             # row * num_cols + (col + 1)

        la      $t3, 12($s0)            # puzzle->board
        add     $t4, $t3, $t0
        lbu     $t9, 0($t4)
        sw      $t9, 44($sp)            # puzzle->board[row * num_cols + col]
        add     $t4, $t3, $t1
        lbu     $t9, 0($t4)
        sw      $t9, 48($sp)            # puzzle->board[(row + 1) * num_cols + col]
        add     $t4, $t3, $t2
        lbu     $t9, 0($t4)
        sw      $t9, 52($sp)            # puzzle->board[row * num_cols + (col + 1)]

        # solution addresses
        add     $t9, $s1, $t0
        sw      $t9, 56($sp)            # &solution[row * num_cols + col]
        add     $t9, $a1, $t1
        sw      $t9, 60($sp)            # &solution[(row + 1) * num_cols + col]
        add     $t9, $a1, $t2
        sw      $t9, 64($sp)            # &solution[row * num_cols + (col + 1)]


        #     int next_row = ((col == num_cols - 1) ? row + 1 : row)
        #     int next_col = (col + 1) % num_cols
        move    $a0, $s2
        move    $a1, $s3
        move    $a2, $s5
        jal     next
        sw      $v0, 36($sp)
        sw      $v1, 40($sp)


#     if (row >= num_rows || col >= num_cols) { return 1 }
        sge     $t0, $s2, $s4
        sge     $t1, $s3, $s5
        or      $t0, $t0, $t1
        beq     $t0, 0, solve_not_base

        li      $v0, 1
        j       solve_end
solve_not_base:

#     if (solution[row * num_cols + col] != 0) { 
#         return solve(puzzle, solution, next_row, next_col) 
#     }
        lw      $t0, 56($sp)
        lb      $t0, 0($t0)
        beq     $t0, 0, solve_not_solved

        move    $a0, $s0
        move    $a1, $s1
        move    $a2, $v0
        move    $a3, $v1
        jal     solve
        j       solve_end

solve_not_solved:
#     unsigned char curr_dots = puzzle->board[row * num_cols + col]
        lw      $t9, 44($sp)            # puzzle->board[row * num_cols + col]

#     if (row < num_rows - 1 && solution[(row + 1) * num_cols + col] == 0) {
        sub     $t5, $s4, 1
        bge     $s2, $t5, end_vert

        lw      $t0, 60($sp)
        lbu     $t8, 0($t0)             # solution[(row + 1) * num_cols + col]
        bne     $t8, 0, end_vert 

#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[(row + 1) * num_cols + col],
#                                         max_dots)
        move    $a0, $t9
        lw      $a1, 48($sp)
        move    $a2, $s6
        jal     encode_domino
        sw      $v0, 68($sp)

#         if (dominos_used[domino_code] == 0) {
        add     $t0, $s7, $v0
        lbu     $t1, 0($t0)
        bne     $t1, 0, end_vert

#             dominos_used[domino_code] = 1
        li      $t1, 1
        sb      $t1, 0($t0)

#             solution[row * num_cols + col] = domino_code
#             solution[(row + 1) * num_cols + col] = domino_code
        lw      $t0, 56($sp)
        sb      $v0, 0($t0)
        lw      $t0, 60($sp)
        sb      $v0, 0($t0)

        
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1
#             }
        move    $a0, $s0
        move    $a1, $s1
        lw      $a2, 36($sp)
        lw      $a3, 40($sp)
        jal     solve
        beq     $v0, 0, end_vert_if
        
        li      $v0, 1
        j       solve_end
end_vert_if:

#             dominos_used[domino_code] = 0
        lw      $v0, 68($sp)            # domino_code
        add     $t0, $v0, $s7
        sb      $zero, 0($t0)
        
#             solution[row * num_cols + col] = 0
        lw      $t0, 56($sp)
        sb      $zero, 0($t0)
#             solution[(row + 1) * num_cols + col] = 0
        lw      $t0, 60($sp)
        sb      $zero, 0($t0)
#         }
#     }

end_vert:

#     if (col < num_cols - 1 && solution[row * num_cols + (col + 1)] == 0) {
        sub     $t5, $s5, 1
        bge     $s3, $t5, ret_0
        lw      $t0, 64($sp)
        lbu     $t1, 0($t0)             # solution[row * num_cols + (col + 1)]
        bne     $t1, 0, ret_0

#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[row * num_cols + (col + 1)],
#                                         max_dots)
        lw      $a0, 44($sp)            # puzzle->board[row * num_cols + col]
        lw      $a1, 52($sp)
        move    $a2, $s6
        jal     encode_domino
        sw      $v0, 68($sp)

#         if (dominos_used[domino_code] == 0) {
        add     $t0, $s7, $v0
        lbu     $t1, 0($t0)
        bne     $t1, 0, ret_0
        
#             dominos_used[domino_code] = 1
        li      $t1, 1
        sb      $t1, 0($t0)

#             solution[row * num_cols + col] = domino_code
        lw      $t0, 56($sp)
        sb      $v0, 0($t0)
#             solution[row * num_cols + (col + 1)] = domino_code
        lw      $t0, 64($sp)
        sb      $v0, 0($t0)
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1
#             }
        move    $a0, $s0
        move    $a1, $s1
        lw      $a2, 36($sp)
        lw      $a3, 40($sp)
        jal     solve
        beq     $v0, 0, end_horz_if
        
        li      $v0, 1
        j       solve_end
end_horz_if:



#             dominos_used[domino_code] = 0
        lw      $v0, 68($sp) # domino_code
        add     $t0, $s7, $v0 
        sb      $zero, 0($t0)
        
#             solution[row * num_cols + col] = 0
        lw      $t0, 56($sp)
        sb      $zero, 0($t0)
#             solution[row * num_cols + (col + 1)] = 0
        lw      $t0, 64($sp)
        sb      $zero, 0($t0)
#         }
#     }
#     return 0
# }
ret_0:
        li      $v0, 0

solve_end:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        lw      $s6, 28($sp)
        lw      $s7, 32($sp)
        add     $sp, $sp, 80
        jr      $ra

# // zero out an array with given number of elements
# void zero(int num_elements, unsigned char* array) {
#     for (int i = 0 i < num_elements i++) {
#         array[i] = 0
#     }
# }
zero:
        li      $t0, 0          # i = 0
zero_loop:
        bge     $t0, $a0, zero_end_loop
        add     $t1, $a1, $t0
        sb      $zero, 0($t1)
        add     $t0, $t0, 1
        j       zero_loop
zero_end_loop:
        jr      $ra

# // the slow solve entry function,
# // solution will appear in solution array
# // return value shows if the dominosa is solved or not
# int slow_solve_dominosa(dominosa_question* puzzle, unsigned char* solution) {
#     zero(puzzle->num_rows * puzzle->num_cols, solution)
#     zero(MAX_MAXDOTS * MAX_MAXDOTS, dominos_used)
#     return solve(puzzle, solution, 0, 0)
# }
# // end of solution
# /*** end of the solution to the puzzle ***/
slow_solve_dominosa:
        sub     $sp, $sp, 16
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)

        move    $s0, $a0
        move    $s1, $a1

        # zero(puzzle->num_rows * puzzle->num_cols, solution)
        lw      $t0, 0($s0)
        lw      $t1, 4($s0)
        mul     $a0, $t0, $t1
        jal     zero

        # zero(MAX_MAXDOTS * MAX_MAXDOTS + 1, dominos_used)
        li      $a0, 226
        la      $a1, 268($s0)
        jal     zero

        # return solve(puzzle, solution, 0, 0)
        move    $a0, $s0
        move    $a1, $s1
        li      $a2, 0
        li      $a3, 0
        jal     solve

        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        add     $sp, $sp, 16

        jr      $ra        

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
        li      $s1, 1
        j       interrupt_dispatch      # see if other interrupts are waiting

request_puzzle_interrupt:
        sw      $0, REQUEST_PUZZLE_ACK
        li      $t0, 1
        sw      $t0, has_puzzle
        j	interrupt_dispatch

timer_interrupt:
        sw      $0, TIMER_ACK
        li      $s2, 1
        j       interrupt_dispatch
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
