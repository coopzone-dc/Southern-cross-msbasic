These programs have been tested using real hardware and have been compiled with TASM (others should work)

Step 1 Compile the intsc.asm file (this is a startup routene and serial I/O)

  tasm -t80 -fff -c intsc.asm intsc.hex
(this produces a hex file depending on your eprom programmer it may be better to use a binary file, add -g3)

Step 2 Compile basic (or use the existing pre-compiled hex file)

  tasm -t80 -fff -c basic.asm basic.hex
(this produces a hex file depending on your eprom programmer it may be better to use a binary file, add -g3)

Step 3 combine the two files.

Depending on your programmer, it should be possible to just load the two files and effectiv;y merge
them ready to write the eprom. You need to get the intsc file to load at 0000 and the basic file to
load at 0200.

To procude a single file scbasic.hex; edit the intsc.hex file and delete the 'end of file' record IE
the last line, looks like :00000001FF

now copy the files or cat them (linux) to one file.

cat intsc.hex basic.hex > scbasic.hex

this files can be loaded into the programmer and used

Step 4 program the eprom 

It's alsoo possible to use the scbasic.hex or the scbasic.bin (converted binary file from hex file)

have fun

