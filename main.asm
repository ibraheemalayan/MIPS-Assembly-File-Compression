.data

buffer: .space 256    # Space to store long input strings
words_array: .space 2048 # Space to store the words
words_count: .word 0 # number of words in the dictionary

# default file name 
default_file_name: .asciiz "dictionary.txt"

# prompts
prompt_file_exists: .asciiz "\ndoes the dictionary.txt file exist ? [yes/no]\n> "
prompt_file_path: .asciiz "\nEnter the file path: \n> "
prompt_creating_file: .asciiz "\nOk, creating the file..."
prompt_quitting: .asciiz "\nQuitting..."
prompt_error_reading_file: .asciiz "\nError reading file"
prompt_error_fixing_file_path: .asciiz "\nError fixing file path"

prompt_closing_files: .asciiz "\nClosing files..."

dictionary_read_file_descriptor: .space 2 # descriptor is 2 bytes long
dictionary_write_file_descriptor: .space 2 # descriptor is 2 bytes long

.text
.globl main

main:
    # Print: does the dictionary.txt file exist ? [yes/no]
    li $v0, 4 # print string syscall
    la $a0, prompt_file_exists # address of the string on a0
    syscall

    # Read the answer
    li $v0, 8 # read string syscall
    la $a0, buffer # address of the string on a0
    li $a1, 4 # max length of the string
    syscall

    # Check if the answer is yes
    li $t0, 'y'
    lb $t1, buffer
    beq $t0, $t1, yes

    # create the file
    li $v0, 4 # print string syscall
    la $a0, prompt_creating_file # address of the string on a0
    syscall

    # # creates dictionary.txt if it doesn't exist
    # li $v0, 13 # create file syscall
    # la $a0, default_file_name # address of the string on a0
    # li $a1, 1 # write only
    # li $a2, 0 # ignored in MARS simulator
    # syscall

    # # store file descriptor in dictionary_write_file_descriptor
    # sh $v0, dictionary_write_file_descriptor

    j open_file

yes:
    # Print: Enter the file path:
    li $v0, 4 # print string syscall
    la $a0, prompt_file_path # address of the string on a0
    syscall

    # Read the file path
    li $v0, 8 # read string syscall
    la $a0, buffer # address of the string on a0
    li $a1, 128 # max length of the string
    syscall

    # Remove newline character from the path
    la $t0, buffer              # Load path address into $t0
    addi $t1, $t0, 255       # Point $t1 to the last character
    
find_length:
    lbu $t2, ($t1)        # Load the character
    
    # Check if it's a new line character
    li $t4, '\n'
    beq $t2, $t4, remove_newline
    
    addi $t1, $t1, -1    # Decrement pointer
    j find_length

remove_newline:
    beqz $t1, open_file    # If the pointer reached the start, open the file
    
    sb $zero, ($t1)       # Replace newline with null character

    j open_file

reached_start_of_buffer:
    # Print: prompt_error_fixing_file_path
    li $v0, 4 # print string syscall
    la $a0, prompt_error_fixing_file_path # address of the string on a0
    syscall

    j quit

open_file:

    # Open the file
    li $v0, 13 # open file syscall
    la $a0, buffer # address of the string on a0
    li $a1, 0 # read only
    li $a2, 0 # ignored in MARS simulator
    syscall

    # store file descriptor in dictionary_read_file_descriptor
    sh $v0, dictionary_read_file_descriptor

read_file:

    la $t0, buffer            # Load buffer address into $t0
    la $t1, words_array       # Load array address into $t1
    lw $t2, words_count       # Load words_count into $t2

    lw $a0, dictionary_read_file_descriptor # load file descriptor into $a0

read_file_loop:
    li $v0, 14                # Read from file
    move $a1, $t0             # Buffer address into $a1
    li $a2, 32               # Maximum number of characters to read
    syscall

    # check if v0 is negative then print prompt_error_reading_file else branch to no_error_reading_file
    li $t3, 0
    bge		$v0, $t3, no_error_reading_file	# if $v0 >= 0 then no_error_reading_file

    # Print: Error reading file
    li $v0, 4 # print string syscall
    la $a0, prompt_error_reading_file # address of the string on a0
    syscall
    
    j quit

no_error_reading_file:
    beqz $v0, exit_read_file_loop       # Exit loop if end-of-file is reached
    
    sw $t0, 0($t1)               # Store the line address in the array
    addi $t1, $t1, 4         # Increment the array pointer
    addi $t2, $t2, 1          # Increment words_count
    
    li $v0, 4                 # Print the line
    move $a0, $t0             # Line address into $a0
    syscall
    
    la $t0, buffer            # Reset the buffer address
    
    j read_file_loop
    
exit_read_file_loop:
    sw $t2, words_count        # Store the words_count


quit:    

    # Print: Quitting...
    li $v0, 4 # print string syscall
    la $a0, prompt_quitting # address of the string on a0
    syscall

    # Print: Closing files...
    li $v0, 4 # print string syscall
    la $a0, prompt_closing_files # address of the string on a0
    syscall


    # close the read file descriptors if open
    lh $t0, dictionary_read_file_descriptor
    beqz $t0, close_write_file
    li $v0, 16 # close file syscall
    lh $a0, dictionary_read_file_descriptor
    syscall

close_write_file:
    lh $t0, dictionary_write_file_descriptor
    beqz $t0, files_closed
    li $v0, 16 # close file syscall
    lh $a0, dictionary_write_file_descriptor
    syscall

files_closed:

    # Exit the program
    li $v0, 10
    syscall
