.eqv SEPARATOR '~' # unit separator

.data
dictionary: .asciiz "Hello~ ~am~a~:~\n~birzeit~.~studying~computer"   # Assuming "dictionary" is defined in the .data section
word: .asciiz "stud"    # Assuming "word" is defined in the .data section

.text
.globl main



# Function

main:

    la $a0, word

    li $t0, 0       # i = 0
    li $t1, 0       # j = 0
    li $t2, 0       # word_index = 0

    li $t3, 0       # go_to_next_word = False

while_loop:
    lb $t4, dictionary($t0)     # dict_char = dictionary[i]

    add $t6, $t0, $a0         # t6 = address( word + j )
    lb $t5, 0($t6)           # word_char = word[j]

    bne $t4, $zero, check_go_to_next_word   # If dict_char != '\0', check_go_to_next_word

    
    beq $t5, $zero, return_word_found # if  word_char == '\0' return word_index
    j return_not_found # else return -1


check_go_to_next_word:
    beq $t3, $zero, check_chars # If go_to_next_word == False, check characters

    addi $t0, $t0, 1    # i += 1
    bne $t4, SEPARATOR, while_loop # If dict_char != '~', continue

    li $t1, 0 # j = 0
    addi $t2, $t2, 1 # word_index += 1
    li $t3, 0 # go_to_next_word = False

    j while_loop

check_chars:

    # if dict_char == word_char:
            # i += 1
            # j += 1
            # continue
    bne $t4, $t5, check_end_of_dict_and_word  # If dict_char != word_char, check_end_of_dict_and_word
    addi $t0, $t0, 1    # i += 1
    addi $t1, $t1, 1    # j += 1
    j while_loop

check_end_of_dict_and_word:

    #  elif (
            # dict_char == "~" or dict_char == "\0"
        # ) and word_char == "\0":  # check_end_of_dict_and_word
            # return word_index  # move word index to v0 and jr s7
    
    # if t5 != "\0" or (t4 != "~" and t4 != "\0"):
    #     j check_end_of_dict
    bne $t5, $zero, check_end_of_dict

    # if (t4 != "~" and t4 != "\0"):
    #     j check_end_of_dict
    # else:
    #     j word_and_dict_ended
    
    beq $t4, SEPARATOR, word_and_dict_ended
    bne $t4, $zero, check_end_of_dict

word_and_dict_ended:
    j return_word_found

check_end_of_dict:

    # if dict_char == "\0":
    #       j return_not_found
    beq $t4, $zero, return_not_found
    
check_end_of_dict_word:

    # if dict_char == "~":
        # i += 1
        # j = 0
        # word_index += 1
        # continue 

    # if t4 != "~":
    #     j check_end_of_word

    bne $t4, SEPARATOR, check_end_of_word

    # else

    addi $t0, $t0, 1    # i += 1
    li $t1, 0           # j = 0
    addi $t2, $t2, 1    # word_index += 1
    j while_loop

check_end_of_word:

    # if word_char == "\0" or dict_char != word_char:  # check_end_of_word
        # j = 0
        # i += 1
        # go_to_next_word = True
        # continue  # j while_loop

    beq $t5, $zero, end_of_word
    bne $t4, $t5, end_of_word

    j error_in_compresion
    
end_of_word:

    li $t1, 0           # j = 0
    addi $t0, $t0, 1    # i += 1
    li $t3, 1           # go_to_next_word = True
    j while_loop

error_in_compresion:
    li $v0, -2          # Return -2 (error)
    j exit_program

return_not_found:
    li $v0, -1          # Return -1 (word not found)
    j exit_program
return_word_found:
    move $v0, $t2       # Move word_index to $v0 (return value)
    j exit_program

exit_program:

    move $v1, $v0       # Move return value to $v1



    li $v0, 10          # Exit program
    syscall
