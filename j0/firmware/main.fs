include crossj1.fs

variable filebase

: suffix ( addr u -- addr u ) \ append suffix to basename
    0 padc !
    filebase @ count pad+
    pad+
    pad padc @
;
: create-output-file w/o create-file throw to outfile ;
: cbyte s" 0x" type s>d <# # # #> type [char] , emit ;
hex
variable hiaddr
: coderange hiaddr @ 2B00 ;
: dumpall \ dump the target memory in every useful format
    hex

    \ .lst file is a human-readable disassembly 
    s" .lst" suffix create-output-file
    coderange tuck - 2/ disassemble-block

    \ .binbe is a big-endian binary memory dump
    s" .binbe" suffix create-output-file
    coderange do i t@ dup 8 rshift emit emit 2 +loop

    \ .binle is a little-endian binary memory dump
    s" .binle" suffix create-output-file
    coderange do i t@ dup emit 8 rshift emit 2 +loop

    \ .h is a little-endian memory dump of bytes 2B00-2BFF
    s" .h" suffix create-output-file
    s" static PROGMEM prog_uchar " type
    filebase @ count type
    s" _code[] = {" type cr
    coderange do i t@ dup cbyte 8 rshift cbyte cr 2 +loop
    s" };" type cr
;
decimal
: start-microcode
    bl parse preserve filebase !
    s" marker revert h# 2B02 org" evaluate
    coldcross decimal
;
: end-microcode 
    there hiaddr !
    s" h# 2B00 org code 0jump main ubranch end-code revert meta" evaluate
    dumpall
    s" target" evaluate
;

meta
coldcross
include basewords.fs
target
include hwdefs.fs

\ Build all these microcode files:

include memtest.fs
include helloworld.fs
include flowtest.fs
include setpixel.fs
include wireframe.fs
include eraser.fs
include splitscreen.fs
include selftest1.fs
include reload.fs
include palcopy.fs
include random.fs
include rasterinterrupt.fs
include soundbuffer.fs
include cold.fs
include testflash.fs
include thrasher.fs
include bgstripes.fs
include dna.fs
include regressfreq.fs
include showvoices.fs
include spectrum.fs
include fullscreen_bitmap.fs
include videocopy.fs
include spr512.fs
\ include eforth.fs

meta
