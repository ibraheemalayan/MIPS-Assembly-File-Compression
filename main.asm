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
# buffer size was set to a big number in order to read the file once, instead of chuncks, to avoid reading half of a word in a chunk and another half in the next chunk

# #############################################################################
# ################################# VARIABLES #################################
# #############################################################################

.data
smallBuffer: .space 32    # Space to buffer small strings
wordsCount: .word 0 # number of words in the dictionary
dictionaryReadFileDescriptor: .space 2 # descriptor is 2 bytes long
dictionaryWriteFileDescriptor: .space 2 # descriptor is 2 bytes long
buffer: .space BUFFER_SIZE    # Space to store long input strings
wordsArray: .space BUFFER_SIZE # Space to store the words ( dictionary ) as SEPARATOR separated strings

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

chooseOperationPrompt:     .asciiz "Choose the operation (C for compression, D for decompression, Q to quit): "
errorMsg:  .asciiz "Invalid choice. Please try again.\n"
compressMsg: .asciiz "Compression function called.\n"
decompressMsg: .asciiz "Decompression function called.\n"


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

    # Remove newline character from the path
    la $t0, buffer              # Load path address into $t0
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
    jr $ra

# ############################### File Functions ##############################

# Function
# $a0 - First argument, $a1 - Second argument
load_dictionary:
    nop


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

    # create the file
    li $v0, 4 # print string syscall
    la $a0, promptCreatingFile # address of the string on a0
    syscall

    # # creates dictionary.txt if it doesn't exist
    # li $v0, 13 # create file syscall
    # la $a0, defaultFileName # address of the string on a0
    # li $a1, 1 # write only
    # li $a2, 0 # ignored in MARS simulator
    # syscall

    # # store file descriptor in dictionaryWriteFileDescriptor
    # sh $v0, dictionaryWriteFileDescriptor

    j open_file

yes:
    # Print: Enter the file path:
    li $v0, 4 # print string syscall
    la $a0, promptFilePath # address of the string on a0
    syscall

    # Read the file path
    li $v0, 8 # read string syscall
    la $a0, buffer # address of the string on a0
    li $a1, BUFFER_SIZE_MINUS_ONE # max length of the string
    syscall

    jal RemoveNewline

    j open_file

reached_start_of_buffer:
    # Print: promptErrorFixingFilePath
    li $v0, 4 # print string syscall
    la $a0, promptErrorFixingFilePath # address of the string on a0
    syscall

    j quit

open_file:

    # Open the file
    li $v0, 13 # open file syscall
    la $a0, buffer # address of the string on a0
    li $a1, 0 # read only
    li $a2, 0 # ignored in MARS simulator
    syscall

    # store file descriptor in dictionaryReadFileDescriptor
    sh $v0, dictionaryReadFileDescriptor

read_file:

    la $t0, wordsArray       # Load wordsArray address into $t0
    la $t1, wordsArray       # Load array address into $t1
    lw $t2, wordsCount       # Load wordsCount into $t2

read_file_loop:

    li $v0, 14                      # Read from file
    lh $a0, dictionaryReadFileDescriptor # load file descriptor into $a0
    move $a1, $t0                   # wordsArray address into $a1
    li $a2, BUFFER_SIZE_MINUS_ONE   # Maximum number of characters to read
    syscall

    beqz $v0, exit_read_file_loop       # Exit loop if end-of-file is reached
    
    li $v0, 4                 # Print the block of text
    move $a0, $t0             # block address into $a0
    syscall
    
    la $t0, buffer            # Reset the buffer address
    
    j read_file_loop
    
exit_read_file_loop:

    # TODO menu


quit:    

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
