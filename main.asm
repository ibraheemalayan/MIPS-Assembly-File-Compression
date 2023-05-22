# author: Ibraheem Alyan
# date: 2023-5-20

# style guide

# 1. use spaces for indentation
# 2. use snake-case for labels
# 3. use pascal-case for function names
# 4. use camel-case for variables




# #############################################################################
# ################################ DEFINITIONS ################################
# #############################################################################

# similar to define in c
.eqv BUFFER_SIZE 2048 
.eqv BUFFER_SIZE_MINUS_ONE 2047
.eqv SEPARATOR '~' # unit separator
# mainBuffer size was set to a big number in order to read the file once, instead of chuncks, to avoid reading half of a word in a chunk and another half in the next chunk

# #############################################################################
# ################################# VARIABLES #################################
# #############################################################################

.data
smallBuffer: .space 32    # Space to buffer small strings
wordsCount: .word 0 # number of words in the dictionary
inputFileDescriptor: .space 2 # descriptor is 2 bytes long ( half word )
outputFileDescriptor: .space 2 # descriptor is 2 bytes long ( half word )
dictionaryReadFileDescriptor: .space 2 # descriptor is 2 bytes long ( half word )
dictionaryWriteFileDescriptor: .space 2 # descriptor is 2 bytes long ( half word )
mainBuffer: .space BUFFER_SIZE    # Space to store long input strings
wordsArray: .space BUFFER_SIZE # Space to store the words ( dictionary ) as SEPARATOR separated strings
secondaryBuffer: .space BUFFER_SIZE    # Space to store temporary data
word: .space 128

# #############################################################################
# ################################## PROMPTS ##################################
# #############################################################################

# default file name 
defaultDictionaryName: .asciiz "dictionary.txt"
defaultCompressedOutputName: .asciiz "compressed.bin"
defaultDecompressedOutputName: .asciiz "decompressed.txt"

# prompts
promptFileExists: .asciiz "\ndoes the dictionary.txt file exist ? [yes/no]\n> "
promptFilePath: .asciiz "\nEnter the file path: \n> "
promptCreatingFile: .asciiz "\nOk, creating the file..."
promptQuitting: .asciiz "\nQuitting..."
promptErrorReadingFile: .asciiz "\nError reading file, error code: "
promptErrorWritingFile: .asciiz "\nError writing to file, error code: "
promptErrorFixingFilePath: .asciiz "\nError fixing file path"
promptClosingFiles: .asciiz "\nClosing files..."
compressedSizePrompt: .asciiz "\nCompressed file size: "
uncompressedSizePrompt: .asciiz "\nUncompressed file size: "
compressionRatioPrompt: .asciiz "\nCompression Ratio: "
dictionaryUpdatedPrompt: .asciiz "\nDictionary updated.\n"
chooseOperationPrompt:     .asciiz "\nChoose the operation (C for compression, D for decompression, Q to quit): \n> "
invalidChoiceMsg:  .asciiz "\nInvalid choice. Please try again.\n"
compressMsg: .asciiz "\nEnter path of text file to compress: \n> "
decompressMsg: .asciiz "\nDecompression function called.\n"
sep: .asciiz "~"


.text
.globl Main

    j Main # jump to main

# #############################################################################
# ################################# FUNCTIONS #################################
# #############################################################################


# ############################## String Functions #############################


# Function
# No arguments
RemoveNewline:

    move $s5, $ra       # save return address in $s5

    # Remove newline character from the path
    la $t0, mainBuffer              # Load path address into $t0
    move $t1, $t0               # Point $t1 to the first character

    li $t4, '\n'
    
loop_to_find_newline:
    lbu $t2, ($t1)        # Load the character
    
    # Check if it's a new line character
    beq $t2, $t4, remove_newline
    
    addi $t1, $t1, 1    # Increment pointer
    j loop_to_find_newline

remove_newline:
   
    sb $zero, ($t1)       # Replace newline with null character

    # Return from the function
    jr $s5

# ############################### File Functions ##############################

# Function
# No arguments
ReadCorrectFilePath:

    move $s6, $ra       # save return address in $s6

    # Read the file path
    li $v0, 8 # read string syscall
    la $a0, mainBuffer # address of the string on a0
    li $a1, BUFFER_SIZE_MINUS_ONE # max length of the string
    syscall

    jal RemoveNewline

    # Return from the function
    jr $s6

# Function ( returns file descriptor in $v1 )
# $a0 : address of file path
# $a1 : address of buffer to read in
ReadFileIntoAddress:

    move $s0, $a1       # move buffer address to $s0
    move $s7, $ra       # save return address in $s7

    # Open the file
    li $v0, 13 # open file syscall
    # $a0 : address of file path
    li $a1, 0 # read only
    li $a2, 0 # ignored in MARS simulator
    syscall

    li $t3, 0
    bge		$v0, $t3, no_error_opening_file	# if $v0 >= 0 then no_error_opening_file
    
error_reading_file:
    # Print: Error reading file
    li $v0, 4 # print string syscall
    la $a0, promptErrorReadingFile # address of the string on a0
    syscall

    j Quit

error_writing_file:

    move $a1, $v0 # move error code to $a0

    # Print: Error writing to file
    li $v0, 4 # print string syscall
    la $a0, promptErrorWritingFile # address of the string on a0
    syscall

    # Print error code
    move $a0, $a1
    li $v0, 1 # print integer syscall
    syscall


    j Quit
    
no_error_opening_file:

    # store file descriptor in dictionaryReadFileDescriptor
    sh $v0, inputFileDescriptor
    move $v1, $v0 # store file descriptor in $v1 to return it
    
read_input_file:

    move $t0, $s0       # move buffer address to $t0

read_input_file_loop:

    li $v0, 14                      # Read from file
    lh $a0, inputFileDescriptor     # load file descriptor into $a0
    move $a1, $t0                   # buffer address into $a1
    li $a2, BUFFER_SIZE_MINUS_ONE   # Maximum number of characters to read
    syscall

    beqz $v0, exit_read_input_file_loop       # Exit loop if EOF is reached
    
    move $t0, $s0   # Reset the buffer address
    
    j read_input_file_loop
    
exit_read_input_file_loop:

    # return from the function
    jr $s7



# ############################## Menu Functions #############################

# Function
# No arguments
ShowMainMenu:
    li $v0, 4
    la $a0, chooseOperationPrompt
    syscall
    
    # Read user input
    li $v0, 8
    la $a0, mainBuffer
    li $a1, 2 # max length of the string
    syscall
    
    # Check user choice
    lb $t0, mainBuffer
    
    # Convert choice to uppercase
    andi $t0, $t0, 0xDF
    
    # Branch based on user choice
    beqz $t0, incorrect_choice     # Branch if choice is null
    
    beq $t0, 'C', Compression     # Branch if choice is 'C'
    beq $t0, 'D', Decompression   # Branch if choice is 'D'
    beq $t0, 'Q', Quit         # Branch if choice is 'Q'

incorrect_choice:
    # Print error message
    li $v0, 4
    la $a0, invalidChoiceMsg
    syscall
    
    j ShowMainMenu     # Restart the program

# ############################## Main Functions #############################

# Function
# $a1 = code ( short integer )
WriteWordCodeToOutput:

    # code already in $a1
    li $t7, 0

    sh $a1, smallBuffer($t7) # store code at the start of smallBuffer

    li $a1, 0
    li $t7, 2
    sh $a1, smallBuffer($t7) # store a null terminator after the code in the smallBuffer

    la $a1, smallBuffer # address of the string on a1

    # Write the code to the output file
    li $v0, 15 # write to file syscall
    lh $a0, outputFileDescriptor # load file descriptor into $a0
    li $a2, 2 # number of bytes to write
    syscall

    # Return from the function
    jr $ra

# Function ( returns index in v0 )
# $a0 = word address
CompressWord:

    move $s4, $ra       # save return address in $s4

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

    move $v1, $t2       # Move return value to $v1
    
    # print index just for debugging
    # move $a0, $v1        # Move return value to $a0
    # li $v0, 1           # Print return value
    # syscall

    # la $a0, sep         # Move return value to $a0
    # li $v0, 4           # Print return value
    # syscall

    # append code to output file
    move $a1, $v1        # Move return value to $a0
    jal WriteWordCodeToOutput

    jr $s4

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
TokenizeTextAndCompress:


    # Create output file
    la $a0, defaultCompressedOutputName
    li $a1, 1 # write-only with create
    li $a2, 0
    li $v0, 13
    syscall

    # store file descriptor
    sh $v0, outputFileDescriptor

    move $s5, $ra
    
    li $s0, 0 # int textIndex = 0;
    li $s1, -1 # int tokenStartIndex = -1;

tokenize_text_loop:
    
    lb $s2, secondaryBuffer($s0) # char currentChar = text[textIndex];

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
    sb $zero, secondaryBuffer($s0) # text[textIndex] = '\0'

    # handle_word(&text[tokenStartIndex]); # TODO
    la $a0, secondaryBuffer
    add $a0 , $a0, $s1
    jal CompressWord

    li $s1, -1 # tokenStartIndex = -1;


token_start_index_is_not_set:

    sb $s2, word($zero) # word[0] = currentChar
    li $t8, 1
    sb $zero, word($t8) # word[1] = '\0'

    # handle_word(&word); # TODO
    la $a0, word
    jal CompressWord

next_iteration:
    addi $s0, $s0, 1 # textIndex++
    j tokenize_text_loop

tokenize_text_end_loop:

    li $t8, -1
    beq $s1, $t8, end_tokeniz_text # if (tokenStartIndex == -1) return

    # handle_word(&text[tokenStartIndex]); # TODO
    la $a0, secondaryBuffer
    add $a0 , $a0, $s1
    jal CompressWord

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

    # ######## update dictionary ########

    
    # count characters of wordsArray until null
    li $t1, 0 # int i = 0;
loop_count_wordsArray:
    lb $t0, wordsArray($t1) # char currentChar = wordsArray[i];
    li $t8, 0
    beq $t0, $t8, break_loop_count_wordsArray # if (currentChar == '\0') break;
    addi $t1, $t1, 1 # i++
    j loop_count_wordsArray
 

break_loop_count_wordsArray:

    lh $a0, dictionaryWriteFileDescriptor # store file descriptor

    # Write the code to the output file
    li $v0, 15 # write to file syscall
    la $a1, wordsArray # address of the dictionary
    move $a2, $t1 # number of bytes to write
    syscall

     # print update dictionary prompt
    la $a0, dictionaryUpdatedPrompt
    li $v0, 4
    syscall

    # # print dictionary for debug
    # la $a0, wordsArray
    # li $v0, 4
    # syscall


    jr $s5    # Return to the caller


# ############################### Menu Options ##############################

# Function
# No arguments
Compression:

    # Print: compressMsg
    li $v0, 4 # print string syscall
    la $a0, compressMsg # address of the string on a0
    syscall

    jal ReadCorrectFilePath # reads the file path into mainBuffer

    la $a0, mainBuffer # address of file path
    la $a1, secondaryBuffer # address of input buffer
    jal ReadFileIntoAddress # reads the file into secondaryBuffer ( and prints it )

    # s3 contains number of tokens compressed
    li $s3, 0

    # Call tokeniz_text function
    la $a0, secondaryBuffer
    jal TokenizeTextAndCompress

    # Exit program
    li $v0, 10
    syscall

    # end program
    j Quit

# Function
# No arguments
Decompression:

    # Print: decompressMsg
    li $v0, 4 # print string syscall
    la $a0, decompressMsg # address of the string on a0
    syscall

    # TODO: decompression function

    # end program
    j Quit


# #############################################################################
# #################################### Main ###################################
# #############################################################################

Main:
    # Print: does the dictionary.txt file exist ? [yes/no]
    li $v0, 4 # print string syscall
    la $a0, promptFileExists # address of the string on a0
    syscall

    # Read the answer
    li $v0, 8 # read string syscall
    la $a0, smallBuffer # address of the string on a0
    li $a1, 4 # max length of the string
    syscall

    # Check if the answer is yes
    li $t0, 'y'
    lb $t1, smallBuffer
    beq $t0, $t1, yes

    # create the file since the answer is no
    li $v0, 4 # print string syscall
    la $a0, promptCreatingFile # address of the string on a0
    syscall

    # creates dictionary.txt if it doesn't exist
    li $v0, 13 # create file syscall
    la $a0, defaultDictionaryName # address of the string on a0
    li $a1, 1 # write only
    li $a2, 0 # ignored in MARS simulator
    syscall

    # store file descriptor in dictionaryWriteFileDescriptor
    sh $v0, dictionaryWriteFileDescriptor

    j dictionary_loaded # jump to exit_read_file_loop to avoid reading the file

yes:
    # Print: Enter the file path:
    li $v0, 4 # print string syscall
    la $a0, promptFilePath # address of the string on a0
    syscall

    jal ReadCorrectFilePath # reads the file path into mainBuffer

load_dictionary:

    la $a0, mainBuffer # address of file path
    la $a1, wordsArray # address of input buffer
    jal ReadFileIntoAddress # reads the file into secondaryBuffer ( and prints it )

    # store file descriptor in dictionaryReadFileDescriptor
    sh $v1, dictionaryReadFileDescriptor

    # close the read file descriptors if open
    lh $t0, dictionaryReadFileDescriptor
    beqz $t0, dictionary_loaded
    li $v0, 16 # close file syscall
    lh $a0, dictionaryReadFileDescriptor
    syscall

    # open dictionary file for write
    la $a0, mainBuffer # address of file path
    li $a1, 1 # write-only with create
    li $a2, 0
    li $v0, 13
    syscall

    sh $v0, dictionaryWriteFileDescriptor # store file descriptor

dictionary_loaded:

    jal ShowMainMenu


Quit:    

    # Print: Quitting...
    li $v0, 4 # print string syscall
    la $a0, promptQuitting # address of the string on a0
    syscall

    # Print: Closing files...
    li $v0, 4 # print string syscall
    la $a0, promptClosingFiles # address of the string on a0
    syscall


    # close the read file descriptors if open
    lh $t0, dictionaryReadFileDescriptor
    beqz $t0, close_write_file
    li $v0, 16 # close file syscall
    lh $a0, dictionaryReadFileDescriptor
    syscall

close_write_file:
    lh $t0, dictionaryWriteFileDescriptor
    beqz $t0, close_output_write_file
    li $v0, 16 # close file syscall
    lh $a0, dictionaryWriteFileDescriptor
    syscall

close_output_write_file:
    lh $t0, outputFileDescriptor
    beqz $t0, files_closed
    li $v0, 16 # close file syscall
    lh $a0, outputFileDescriptor
    syscall

files_closed:

    # Exit the program
    li $v0, 10
    syscall
