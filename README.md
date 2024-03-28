This is a version of MSBasic 4.7, originally used on the NASCOM 2 computer, modified by Grant Searle

Further alterations by Derek Cooper to provide A bootable Rom for the Sothern Cross SBC allowing it to boot into
basic and use the bit-banged serial port at 9600b

It does not need any additional hardware or modifications to the SBC

Issues and limitations.

Serial I/O has no hardware flow control, so you will need to set delays for character and end of line to be
able to past to the console.

Since there is no easy way to check for an ESC key during program run it can take several attampt (possible 50-60) 
to break into a program. If anyone knows a better way to do this please let me know!

Copyrights

I know that the original BASIC Code was released as public domain, but I can't find the exact copyright.

Grant's changes are copyright him with permission to use it.

My changes are complety open source, see the main licence.

Have fun!

