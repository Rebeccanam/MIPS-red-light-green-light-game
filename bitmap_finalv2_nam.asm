#################################################################
#  Red Light Green Light Bitmap Project - CS2340 - Rebecca Nam 	#
#################################################################
# bitmap settings						#
# unit width  4							#
# unit height  4						#
# display width 512						#
# display height 256						#
# base address 0x1004000 (heap)					#
#################################################################

.data
	game_start: .asciiz " \nLets start the game"
	instructions: .asciiz "\nWhen the light is green, press r to start running \nwhen the light is red, press s to stop. \nTraverse across the entire screen to win." 


	winMsg: .asciiz "\nyou won!"
	loseMsg: .asciiz "\nyou lost." 
	
	heapAddress: .word 0x10040000 # starting address of the heap
	# the max width is 512 and the pixel size is 4x4 so width is 512/4 = 128 
	width: .word 128
	base_color: .word 0x0066cc # blue color as a base
	green_color: .word 0x0000ff00 # green color 
	red_color: .word 0x00ff0000   # red color
	player_position: .word  2   # the starting point of the player
	condition: .word 0	   # check the current condition
	keyboard_address: .word 0xffff0004
	rand1: .word 0
	rand2: .word 0
	light_counter: .word 0
	light_color: .word 0x0000ff00

.text
#########################################################################
# main
# the main builds the grid and then iterates in the loop
# to randomly display a green or red light
main:
	# grid draw
	jal draw_grid
	lw $a1, player_position
	jal draw_player
	jal get_random

	#jal draw_light
	la $a0, instructions
	li $v0, 4
	syscall
	li $v0, 32
	li $a0, 2000	# number in milliseconds
	syscall
	la $a0, game_start
	li $v0, 4
	syscall
game_loop:
	jal draw_grid
	lw $a1, player_position
	jal draw_player
	lw $a1, player_position
	jal remove_player
	
	#jal set_light_color
	jal draw_light
	li $v0, 32
	li $a0, 500	# number in milliseconds
	syscall
	jal user_input

	#jal respond_on_input
	jal check_results
	j game_loop
	j exit

####################################################################
user_input:
	lw $t9, keyboard_address
	lw $t9, 0($t9)
	beq $t9, 114, keyboardInputR
	beq $t9,115, keyboardInputS
	jr $ra
	
keyboardInputR:
	lw $t8, player_position
	addi $t8, $t8,1
	sw $t8, player_position
	li $t8, 100
	sw $t8, condition
	jr $ra
	
keyboardInputS:
	li $t8, 200
	sw $t8, condition
	jr $ra
##########################################################################

check_results:
	lw $t0, condition
	lw $t1, light_color
	lw $t2, red_color

	bne $t1, $t2, skip
	beq $t0, 100, lose
skip:
	jr $ra

##################################################################################

remove_player:
	addi $sp, $sp, -4
	sw $ra , 0($sp)
	# move $a1, $a0
	li $a0, 0
	addi $a1, $a1,-1
	move $s1, $a1
	li $a2,  39
	jal fill_pixel

	addi $s1, $s1, 1
	move $a1,$s1
	li $a2, 38
	jal fill_pixel

	addi $s1, $s1, -1
	move $a1,$s1
	li $a2,  37
	jal fill_pixel
	addi $s1, $s1, 1
	move $a1,$s1
	li $a2, 36
	jal fill_pixel

	lw $ra, 0($sp) 
	addi $sp, $sp, 4

	jr $ra
	
###############################################################################

get_random:
	li $v0, 42
	li $a1, 60
	syscall
	sw $a0,rand1
	li $v0, 42
	li $a1, 60
	syscall
	addi $a0, $a0, 60
	sw $a0,rand2
	jr $ra
	
#################################################################################



################################################################################
# Fill the specified color in specified pixel which the coordinates are given in
# $a0  color
# $a1 x cordinate
# $a2 y coordinate

fill_pixel:
	lw $t0, width 		# Store screen width into $v0
	mul $t0, $t0, $a2	# multiply by y position
	add $t0, $t0, $a1	# add the x position
	mul $t0, $t0, 4		# multiply by 4
	lw $t1, heapAddress
	add $t0, $t0, $t1	# add global pointerfrom bitmap display	
	sw $a0, ($t0) 		# fill the coordinate with specified color
	jr $ra			# return
 
###############################################################################
# draw_grid (void)
# (draws the internal grid)

draw_grid:
	addi $sp, $sp -4
	sw $ra, 0($sp)
	li $s1, 0
	li $s2, 5
top_line:
	lw $a0, base_color		# pass base color
	move $a1, $s1			# x coordinates
	move $a2, $s2			# y coordinates
	jal fill_pixel			# jal to function
	addi $s1, $s1, 1
	blt $s1, 128, top_line

	li $s1, 0
	li $s2, 63
bottom_line:
	lw $a0, base_color		# pass base color
	move $a1, $s1			# x coordinates
	move $a2, $s2			# y coordinates
	jal fill_pixel			# jal to function
	addi $s1, $s1, 1
	blt $s1, 128, bottom_line

	li $s1, 0
	li $s2, 5
left_line:
	lw $a0, base_color		# pass base color
	move $a1, $s1			# x coordinates
	move $a2, $s2			# y coordinates
	jal fill_pixel			# jal to function
	addi $s2, $s2, 1
	blt $s2, 64, left_line

	li $s1, 127
	li $s2, 5
right_line:
	lw $a0, base_color		# pass base color
	move $a1, $s1			# x coordinates
	move $a2, $s2			# y coordinates
	jal fill_pixel			# jal to function
	addi $s2, $s2, 1
	blt $s2, 64, right_line
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra



######################################################################################
# draw player icon  (pixel poxition of the payer)
# a1 = pixel position of player
draw_player:
	addi $sp, $sp, -4
	sw $ra , 0($sp)
	# move $a1, $a0
	lw $a0, green_color
	move $s1, $a1
	li $a2,  39
	jal fill_pixel
	addi $s1, $s1,1
	move $a1,$s1
	li $a2, 39
	jal fill_pixel
	addi $s1, $s1,1
	move $a1,$s1
	li $a2, 39
	jal fill_pixel

	addi $s1, $s1, -1
	move $a1,$s1
	li $a2, 38
	jal fill_pixel

	addi $s1, $s1, -1
	move $a1,$s1
	li $a2,  37
	jal fill_pixel
	addi $s1, $s1, 1
	move $a1,$s1
	li $a2, 37
	jal fill_pixel
	addi $s1, $s1,1
	move $a1,$s1
	li $a2, 37
	jal fill_pixel

	addi $s1, $s1,-1
	move $a1,$s1
	li $a2, 36
	jal fill_pixel

	lw $ra, 0($sp) 
	addi $sp, $sp, 4

	jr $ra
	
#################################################################################
# draw stoplight
# $a0 = light color

draw_light:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lw $a0, green_color
	lw $t0, rand1
	addi $t2, $t0, 5
	lw $t1, light_counter
set_light_color:
	blt $t1, $t0, skp1  
	bgt $t1, $t2, skp1 
	lw $a0, red_color
skp1:
	lw $t0, rand2
	addi $t2, $t0, 5
	lw $t1, light_counter

	blt $t1, $t0, skp2  
	bgt $t1, $t2, skp2 
	lw $a0, red_color
skp2:
	addi $t1, $t1,1
	sw $t1, light_counter

	sw $a0, light_color
	li $s2, 0
	move $a2, $s2
light_loop2:
	li $s1, 122
light_loop1:
	move $a1, $s1
	jal fill_pixel
	addi $s1, $s1, 1
	blt $s1, 126, light_loop1
	addi $s2, $s2,1
	move $a2, $s2
	blt $s2, 5, light_loop2
	lw $ra, 0($sp) 
	addi $sp, $sp, 4
	jr $ra

lose:
	la $a0, loseMsg
	li $v0, 4
	syscall
exit:
	li $v0, 10
	syscall