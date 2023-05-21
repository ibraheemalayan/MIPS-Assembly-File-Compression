.eqv SEPARATOR '~' # unit separator

.data
    text: .asciiz "Enter the text: Hi there, how are you?\n the shit"
    word: .space 100       # Buffer to hold the current word
    newline: .asciiz "\n"   # Newline character
    sep: .asciiz "~"       # Separator character
    wordsArray: .asciiz "text~ ~Nigga~a~:~\n~Hello~.~studying~:~you"   # Assuming "wordsArray" is defined in the .data section
    empty: .space 100
    compressedSizePrompt: .asciiz "\nCompressed file size: "
    uncompressedSizePrompt: .asciiz "\nUncompressed file size: "
    compressionRatioPrompt: .asciiz "\nCompression Ratio: "
.text
.glob main 

main:

    # s3 contains number of tokens compressed
    li $s3, 0

    # Call tokeniz_text function
    la $a0, text
    jal TokenizeText

    # Exit program
    li $v0, 10
    syscall

# Function ( returns index in v0 )
# $a0 = word address
FindWordInwordsArray:

    addi $s3, $s3, 1 # increment number of compressed tokens

    li $t0, 0       # i = 0
    li $t1, 0       # j = 0
    li $t2, 0       # word_index = 0

    li $t3, 0       # go_to_next_word = False

while_loop:
    lb $t4, wordsArray($t0)     # dict_char = wordsArray[i]

    add $t6, $a0, $t1    # word_ptr += t1
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
    j append_if_minus

return_not_found:
    li $v0, -1          # Return -1 (word not found)
    j append_if_minus
return_word_found:
    move $v0, $t2       # Move word_index to $v0 (return value)
    j append_if_minus

append_if_minus:

    # if return value is negative, append it to the end of the wordsArray
    bge $v0, $zero, return_index
append_word:

    li $t5, SEPARATOR           # word[j] = delimeter
    sb $t5, wordsArray($t0) # wordsArray[i] = word[j]

    addi $t0, $t0, 1    # i += 1

    li $t1, 0           # j = 0

    addi $t2, $t2, 1    # word_index += 1
    
append_loop:

    # while (word[j] != '\0'):
    #     wordsArray[i] = word[j]
    #     j += 1
    
    add $t6, $a0, $t1    # word_ptr += j
    lb $t5, 0($t6)           # word_char = word[j]

    beq $t5, $zero, return_index # If word_char == '\0', return index
    sb $t5, wordsArray($t0) # wordsArray[i] = word[j]
    addi $t0, $t0, 1    # i += 1
    addi $t1, $t1, 1    # j += 1
    j append_loop

return_index:

    move $v1, $t2       # Move return value to $v0
    
    # print index just for debugging
    move $a0, $v1        # Move return value to $a0
    li $v0, 1           # Print return value
    syscall

    la $a0, sep         # Move return value to $a0
    li $v0, 4           # Print return value
    syscall

    jr $ra

# Function
# args: $a3 - input
IsCharAlpha:

    # Convert choice to uppercase
    andi $a3, $a3, 0xDF

    # if (input >= 'A' && input <= 'Z') return 1;
    # eqv to
    # if (input < 'A' || input > 'Z') return 0;
    li $t8, 'A'
    li $t9, 'Z'
    bgt $a3, $t9, return_0
    blt $a3, $t8, return_0

    li $v0, 1
    jr $ra

return_0:
    li $v0, 0
    jr $ra


# Function
# args: No args
TokenizeText:

    move $s5, $ra
    
    li $s0, 0 # int textIndex = 0;
    li $s1, -1 # int tokenStartIndex = -1;

tokenize_text_loop:
    
    lb $s2, text($s0) # char currentChar = text[textIndex];

    #  if (currentChar == '\0') break;
    beqz $s2, tokenize_text_end_loop

    move $a3, $s2
    jal IsCharAlpha

    # if (!IsCharAlpha(currentChar)) j character_is_not_alpha
    beqz $v0, character_is_not_alpha

    li $t8, -1
    bne $s1, $t8, next_iteration # if (tokenStartIndex != -1) j next_iteration

    move $s1, $s0   # tokenStartIndex = textIndex;

    j next_iteration

character_is_not_alpha:

    #  {
        # text[textIndex] = '\0';
        # handle_word(&text[tokenStartIndex]);
        # tokenStartIndex = -1;
    # }
    
    # if (tokenStartIndex == -1) j token_start_index_is_not_set
    li $t8, -1
    beq $s1, $t8, token_start_index_is_not_set 

    # else
    sb $zero, text($s0) # text[textIndex] = '\0'

    # handle_word(&text[tokenStartIndex]); # TODO
    la $a0, text
    add $a0 , $a0, $s1
    jal FindWordInwordsArray

    li $s1, -1 # tokenStartIndex = -1;


token_start_index_is_not_set:

    sb $s2, word($zero) # word[0] = currentChar
    li $t8, 1
    sb $zero, word($t8) # word[1] = '\0'

    # handle_word(&word); # TODO
    la $a0, word
    jal FindWordInwordsArray

next_iteration:
    addi $s0, $s0, 1 # textIndex++
    j tokenize_text_loop

tokenize_text_end_loop:

    li $t8, -1
    beq $s1, $t8, end_tokeniz_text # if (tokenStartIndex == -1) return

    # handle_word(&text[tokenStartIndex]); # TODO
    la $a0, text
    add $a0 , $a0, $s1
    jal FindWordInwordsArray

end_tokeniz_text:

    # s0 contains chars of uncompressed file
    # s3 contains chars of compressed file

    # Print uncompressedSizePrompt
    la $a0, uncompressedSizePrompt
    li $v0, 4
    syscall

    # Print integer stored in $s0
    move $a0, $s0
    li $v0, 1
    syscall

    # Print compressedSizePrompt
    la $a0, compressedSizePrompt
    li $v0, 4
    syscall

    # Print integer stored in $s3
    move $a0, $s3
    li $v0, 1
    syscall

    # Print compressionRatioPrompt
    la $a0, compressionRatioPrompt
    li $v0, 4
    syscall

    mtc1 $s0, $f10
    cvt.s.w $f10, $f10

    mtc1 $s3, $f11
    cvt.s.w $f11, $f11

    # Calculate compression ratio
    div.s $f12, $f10, $f11

    # Print float stored in $f12
    li $v0, 2
    syscall

    # print words array
    la $a0, wordsArray
    li $v0, 4
    syscall


    jr $s5    # Return to the caller