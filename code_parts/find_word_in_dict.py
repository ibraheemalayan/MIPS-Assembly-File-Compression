dictionary = "I~ ~am~a~student~\n~birzeit~university~studying~computer\0"

sentence = "am I student studying computer"


def find_word_index(word):
    i = 0
    j = 0
    word_index = 0

    go_to_next_word = False

    while True:  # while_loop
        # print("i: ", i, "j: ", j, "word_index: ", word_index)

        dict_char = dictionary[i]
        word_char = word[j]

        if dict_char == "\0":
            if word_char != "\0":
                return -1
            else:
                return word_index

        if go_to_next_word:  # check_go_to_next_word
            i += 1
            if dict_char == "~":
                j = 0
                word_index += 1
                go_to_next_word = False

            continue  # j while_loop

        if (
            dict_char == word_char
        ):  # check_chars inverse logic: if dict_char != word_char
            i += 1
            j += 1
            continue  # j while_loop
        elif (
            dict_char == "~" or dict_char == "\0"
        ) and word_char == "\0":  # check_end_of_dict_and_word
            return word_index  # move word index to v0 and jr s7
        elif dict_char == "\0":  # check_end_of_dict
            return -1
        elif dict_char == "~":  # check_end_of_dict_word
            i += 1
            j = 0
            word_index += 1
            continue  # j while_loop
        elif word_char == "\0" or dict_char != word_char:  # check_end_of_word
            j = 0
            i += 1
            go_to_next_word = True
            continue  # j while_loop
        else:  # error
            print("Error")
            exit(1)


print(find_word_index("am\0"))
print(find_word_index("I\0"))
print(find_word_index("student\0"))
print(find_word_index("a\0"))
print(find_word_index("f\0"))
print(find_word_index("fofo\0"))
print(find_word_index("studying\0"))
print(find_word_index("computer\0"))
