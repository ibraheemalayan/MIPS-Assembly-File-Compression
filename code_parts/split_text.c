#include <stdio.h>

int is_alpha(char ch) {
    return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z');
}

void handle_word(char* token) {
    
    printf("Processing token: %s\n", token);
}

void tokeniz_text(char* text) {
    int textIndex = 0;
    int tokenStartIndex = -1;

    while (1) {
        char currentChar;

        currentChar = text[textIndex]

        if (currentChar == '\0')
            break;


        if (is_alpha(currentChar)) {
            if (tokenStartIndex == -1) {
                tokenStartIndex = textIndex;
            }
        } else { // character_is_not_alpha
            if (tokenStartIndex != -1) {
                text[textIndex] = '\0';
                handle_word(&text[tokenStartIndex]);
                tokenStartIndex = -1;
            }

            // token_start_index_is_not_set

            if (currentChar != '\n') { 
                char nonAlphaToken[2] = { currentChar, '\0' };
                handle_word(nonAlphaToken);
            }
        }

        textIndex++;
    }

    if (tokenStartIndex != -1) {
        handle_word(&text[tokenStartIndex]);
    }
}

int main() {
    char text[1000] = "Enter the text: Hi there, m\nhow are you?\n";

    tokeniz_text(text);

    return 0;
}