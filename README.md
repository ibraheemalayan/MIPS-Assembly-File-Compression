# MIPS Assembly File Compression

## Code

[main.asm](./main.asm)

## Description

A MIPS assembly program that compresses/decompresses a file using dictionary-based compression.


## Sample Output

#### Compression

```
does the dictionary.txt file exist ? [yes/no]
> yes
Enter the file path: 
> dictionary.txt

Choose the operation (C for compression, D for decompression, Q to quit): 
> c
Enter path of text file to compress: 
> input.txt

Saving compressed data in compressed.bin ...

Uncompressed file size: 14
Compressed file size: 9
Compression Ratio: 1.5555556
Quitting...
Closing files...
Dictionary updated.

```

#### Decompression

```
does the dictionary.txt file exist ? [yes/no]
> yes
Enter the file path: 
> dictionary.txt

Choose the operation (C for compression, D for decompression, Q to quit): 
> d
Enter path of binary file to decompress: 
> compressed.bin

Saving decompressed data in decompressed.txt ...

Quitting...
Closing files...
Dictionary updated.
```


#### Sample Compressed File

Input (Text)
```
hi what's up ?
are you going with us tonight ?
Nop, I have to study.
```

Dictionary (Text)
```
~test~ ~new~you~dictionary~hi~there~how~are~?~
~I~am~fine~,~what~about~.~'~s~up~going~with~us~tonight~Nop~have~to~study
```

Compressed (Hex)
```hex
         00 01 02 03 04 05 06 07 08 09 0A 0B OC OD 0E OF
00000000 06 00 02 00 10 00 13 00 14 00 02 00 15 00 02 00
00000010 0A 00 0B 00 09 00 02 00 04 00 02 00 16 00 02 00
00000020 17 00 02 00 18 00 02 00 19 00 02 00 0A 00 0B 00
00000030 1A 00 OF 00 02 00 0C 00 02 00 1B 00 02 00 1C 00
00000040 02 00 1D 00 12 00
```

Ratio
```
Uncompressed file size: 68
Compressed file size: 35
Compression Ratio: 1.9428571
```
