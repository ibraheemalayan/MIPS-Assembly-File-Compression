dictionary = "I~ ~am~a~student~\n~birzeit~university~studying~computer\0"

codes = [0, 1, 2, 1, 6]

global sentence
sentence = ["\0"] * 100

global j
j = 0


def add_word_by_code(code):
    i = 0  # t0
    current_word_index = 0  # t1

    global j
    global sentence

    while True:  # while_loop
        dict_char = dictionary[i]
        i += 1

        if (dict_char == "~" or dict_char == "\0") and current_word_index == code:
            # return
            return j
        elif dict_char == "\0":  # check_end_of_dictionary
            print("\n\nError, Code not found\n\n")
            return -1
        elif dict_char == "~" and current_word_index != code:
            current_word_index += 1
            continue  # j while_loop

        if current_word_index == code:
            sentence[j] = dict_char
            j += 1


print("".join(sentence))
add_word_by_code(0)
print("".join(sentence))
add_word_by_code(0)
print("".join(sentence))
add_word_by_code(1)
print("".join(sentence))
add_word_by_code(3)
print("".join(sentence))
add_word_by_code(1)
print("".join(sentence))
add_word_by_code(9)
print("".join(sentence))
add_word_by_code(5)
print("".join(sentence))
add_word_by_code(80)
