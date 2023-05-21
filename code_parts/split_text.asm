.data
    text: .asciiz "Enter the text: Hi there, how are you?\n"
    word: .space 100       # Buffer to hold the current word
    newline: .asciiz "\n"   # Newline character
    sep: .asciiz "~"       # Separator character

.text

main:

    # Call tokeniz_text function
    la $a0, text
    jal TokenizeText

    # Exit program
    li $v0, 10
    syscall


# Function
# args: $a0 - word
PrintWord:
    
    li $v0, 4
    syscall

    la $a0, sep
    li $v0, 4
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
    jal PrintWord

    li $s1, -1 # tokenStartIndex = -1;


token_start_index_is_not_set:


    # if (currentChar == '\n') j next_iteration
    beq $s2, '\n', next_iteration

    # else
    sb $s2, word($zero) # word[0] = currentChar
    li $t8, 1
    sb $zero, word($t8) # word[1] = '\0'

    # handle_word(&word); # TODO
    la $a0, word
    jal PrintWord

next_iteration:
    addi $s0, $s0, 1 # textIndex++
    j tokenize_text_loop

tokenize_text_end_loop:

    li $t8, -1
    beq $s1, $t8, end_tokeniz_text # if (tokenStartIndex == -1) return

    # handle_word(&text[tokenStartIndex]); # TODO
    la $a0, text
    add $a0 , $a0, $s1
    jal PrintWord

end_tokeniz_text:
    jr $s5    # Return to the caller