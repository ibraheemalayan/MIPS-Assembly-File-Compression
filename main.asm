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

# #############################################################################
# ################################## PROMPTS ##################################
# #############################################################################

# default file name 
defaultFileName: .asciiz "dictionary.txt"

# prompts
promptFileExists: .asciiz "\ndoes the dictionary.txt file exist ? [yes/no]\n> "
promptFilePath: .asciiz "\nEnter the file path: \n> "
promptCreatingFile: .asciiz "\nOk, creating the file..."
promptQuitting: .asciiz "\nQuitting..."
promptErrorReadingFile: .asciiz "\nError reading file, error code: "
promptErrorFixingFilePath: .asciiz "\nError fixing file path"
promptClosingFiles: .asciiz "\nClosing files..."

chooseOperationPrompt:     .asciiz "\nChoose the operation (C for compression, D for decompression, Q to quit): \n> "
invalidChoiceMsg:  .asciiz "\nInvalid choice. Please try again.\n"
compressMsg: .asciiz "\nEnter path of text file to compress: \n> "
decompressMsg: .asciiz "\nDecompression function called.\n"


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
    # Print: Error reading file
    li $v0, 4 # print string syscall
    la $a0, promptErrorReadingFile # address of the string on a0
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
    
    li $v0, 4                 # Print the block of text
    move $a0, $t0             # block address into $a0
    syscall
    
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

# Function ( returns word index in $v0, or -1 if not found )
# $a0 : address of word to search for
# uses t4, t5, t6, t7, t8, t9, s0
FindWordInDictionary:

    move $t5, $a0       # move word address to $t5
    la $t6, wordsArray  # load dictionary address into $t6
    
    li $t7, 0           # initialize word index to 0
    li $t8, 0           # initialize character index to 0

    li $s0, '~'         # initialize $s0 to '~' ( delimiter )

find_word_in_dictionary_loop:

    lb $t9, ($t5)       # load character from word into $t9
    lb $t4, ($t6)       # load character from dictionary into $t4

    # if t9 != t4 then go to next word by looping over dictionary chatacters until $s0 is found
    bne $t9, $t4, next_dictionary_character





next_dictionary_character:
    addi $t6, $t6, 1




# character_match:
    
#     beqz $t9, word_found    # if $t9 == 0 then word_found

#     # if $t4 == $s0 == '~' then word_not_found
#     beq $t4, $s0, word_not_found
    
    
#     bne $t9, $t4, word_not_found   # if $t9 != $t10 then word_not_found
    
#     addi $t5, $t5, 1    # increment word address
#     addi $t6, $t6, 1    # increment dictionary address
#     addi $t8, $t8, 1    # increment character index
#     j find_word_in_dictionary_loop




# Function
# No arguments
CompressBuffer:

    la $t0, secondaryBuffer # address of buffer containing the text to compress
    la $t1, wordsArray # address of dictionary




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

    # TODO: compression function

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
    la $a0, defaultFileName # address of the string on a0
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
    beqz $t0, files_closed
    li $v0, 16 # close file syscall
    lh $a0, dictionaryWriteFileDescriptor
    syscall

files_closed:

    # Exit the program
    li $v0, 10
    syscall
