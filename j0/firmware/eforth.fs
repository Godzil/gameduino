meta
0 value _next
variable _lit
variable _invert
variable _equal
variable _plus
variable _mul
variable _rshift
variable _and
variable _or
variable _xor
variable _<
variable _u<
variable _dup
variable _drop
variable _swap
variable _over
variable _c!
variable _!
variable _c@
variable _@
variable _>r
variable _r>
variable _r@
variable _branch
variable _0branch

variable _doconst
variable _dovar
variable _docol
variable _semis
target

start-microcode eforth

\ Interface:
\ COMM+0    instruction pointer
COMM+0 constant IP
: 1+    d# 1 + ;
: @     dup c@ swap 1+ c@ swab or ;
: IP!
    IP ;fallthru
: !     over swab over 1+ c! c! ;

: IP@
    \ COMM+0 c@ COMM+1 c@ swab or ;
    IP @ ;
: fetch \ fetch cell from IP, then increment IP
    IP@ dup d# 2 + IP! @ ;

meta there _lit ! target
t: _lit
    drop
    fetch
    ;fallthru
meta there to _next target
: _next 
    fetch           \ fetch xt
    dup 1+ swap     \ stack the args pointer
    c@ >r ;         \ jump to the code addr

meta
: def there wordstr evaluate ! t: ;
: term _next ubranch t;fallthru ;
target


def _doconst
    @ ;fallthru
def _dovar
    term

def _invert  drop invert        term
def _equal   drop =             term
def _plus    drop +             term
def _mul     drop *             term
def _rshift  drop rshift        term
def _and     drop and           term
def _or      drop or            term
def _xor     drop xor           term
def _<       drop <             term
def _u<      drop u<            term
def _dup     drop dup           term
def _drop    drop drop          term
def _swap    drop swap          term
def _over    drop over          term
def _c!      drop c!            term
def _!       drop !             term
def _c@      drop c@            term
def _@       drop @             term
def _>r      drop >r            term
def _r>      drop r>            term
def _r@      drop r@            term
def _branch  drop fetch IP!     term
def _0branch drop fetch swap if drop else IP! then term

\ start a colon definition: push IP and use args as new IP
def _docol
    IP@ >r ;fallthru
: IP!term
    IP! term

\ end a colon definition: pop IP
def _semis
    drop r> IP!term ;

[ _next ] constant main

end-microcode

meta 0 to outfile

only forth
also metacompiler
also forth definitions also

cr cr cr
4000 value dst
create dstmem 8000 allot

s" dump.eforth" w/o create-file throw value dump.eforth

: dstc@
    dstmem + c@ ;
: dstc!
    dstmem + c! ;
: dst!
    over 8 rshift over 1+ dstc! dstc!  ;
: c>>
    dst dstc!
    dst 1+ to dst ;
: >>
    dst dst!
    dst 2 + to dst ;
: s>> ( addr u -- )
    0 do dup c@ c>> 1+ loop drop ;

0 value 'link

\ These definitions go into the gdforth wordlist

vocabulary gdforth

: gdf-define
    only
    gdforth definitions
    also metacompiler
    also forth
;

: gdf-use
    only
    gdforth definitions
;

gdf-define

0 value >link
: dumpmem
    \ bring vocab pointer up to date
    dst 2 - >link .s dst!
    dstmem 4000 + dst 4000 - dump.eforth write-file throw
;

: meta meta ;

\ name
\ length
\ prev
\ cfa      <--- xt
\ args

: label
    wordstr tuck s>> c>>
    'link >> dst to 'link
    create dst ,
    does> @ >> ;

label gdbranch _branch @ c>>
label gd0branch _0branch @ c>>

: begin dst ;
: again gdbranch >> ;
: until gd0branch >> ;
: if    gd0branch dst 7777 >> ;
: else  gdbranch dst >r 8888 >> dst swap dst! r> ;
: then  dst swap dst! ;
: while gd0branch dst 7777 >> ;
: repeat swap gdbranch >> dst swap dst! ;

label (lit) _lit @ c>>
label invert _invert @ c>>
label =     _equal @ c>>
label +     _plus @ c>>
label *     _mul @ c>>
label rshift _rshift @ c>>
label and   _and @ c>>
label or    _or @ c>>
label xor   _xor @ c>>
label <   _< @ c>>
label u<   _u< @ c>>
label c!    _c!   @ c>>
label !    _!   @ c>>
label c@    _c@   @ c>>
label @    _@   @ c>>
label >r   _>r  @ c>>
label r>   _r>  @ c>>
label r@   _r@  @ c>>
label dup    _dup   @ c>>
label drop    _drop   @ c>>
label swap    _swap   @ c>>
label over    _over   @ c>>
label semis _semis @ c>>

: create   label ;
: constant label _doconst @ c>> >> ;
: variable label _dovar @ c>> 0 >> ;
: ivariable label _dovar @ c>> >> ;         \ initialized variable
: the-link label _dovar @ c>> dst .s to >link 'link >> ;    \ variable init to 'link
: allot    dst +! ;

: bc-var (lit) _dovar @ >> ;
: bc-col (lit) _docol @ >> ;
: bc-const (lit) _doconst @ >> ;
: bc-var#       _dovar @ 0ff and ;
: bc-col#       _docol @ 0ff and ;
: bc-const#     _doconst @ 0ff and ;
: semis#        ['] semis >body @ ;
: literal#      ['] (lit) >body @ ;
: branch#       ['] gdbranch >body @ ;
: 0branch#      ['] gd0branch >body @ ;
: '(lit) (lit) (lit) ;

: \ ['] \ execute ;
: ( ['] ( execute ;

: : label _docol @ c>> ;
: ; semis ;
: x; semis ;    \ alternative name for when ; gets overloaded
: immediate
    'link 3 - dup dstc@ 80 or swap dstc! ;

: h# (lit) h# >> ;
: d# (lit) d# >> ;
: [char] (lit) char >> ;

: fwd4  (lit) dst 4 + >> ;

gdf-use

\ constants used for making code
semis# constant semis#          \ address of the semis word
literal# constant literal#      \ address of the literal word
branch# constant branch#      \ address of the branch word
0branch# constant 0branch#      \ address of the 0branch word

bc-var# constant bc-var#        \ the code byte for _dovar
bc-col# constant bc-col#        \ the code byte for _docol
bc-const# constant bc-const#    \ code byte for _doconst

: 1+ d# 1 + ;
: 1- d# -1 + ;
: <> = invert ;
: 2dup      over over ;
: 0<    d# 0 < ;
: tuck  swap over ;

20 constant BL
0 constant FALSE
-1 constant TRUE

10 ivariable BASE
: HEX ( -- )( 6.2.1660 ) D# 16 BASE ! ;
: DECIMAL ( -- )( 6.1.1170 ) D# 10 BASE ! ;

: NIP ( n1 n2 -- n2 )( 6.2.1930 ( 0x4D ) SWAP DROP ;
: ROT ( n1 n2 n3 -- n2 n3 n1 )( 6.1.2160 ( 0x4A ) >R SWAP R> SWAP ;
: 2DROP ( n n -- )( 6.1.0370 ( 0x52 ) DROP DROP ;
: 2DUP ( n1 n2 -- n1 n2 n1 n2 )( 6.1.0380 ( 0x53 ) OVER OVER ;
: ?DUP ( n -- n n | 0 )( 6.1.0630 ( 0x50 ) DUP IF DUP THEN ;

: INVERT ( n -- n )( 6.1.1720 ( 0x26 ) D# -1 XOR ;

: NEGATE ( n -- n )( 6.1.1910 ( 0x2C ) INVERT D# 1 + ;
: - ( n n -- n )( 6.1.0160 ( 0x1F ) NEGATE + ;
: ABS ( n -- u )( 6.1.0690 ( 0x2D ) DUP 0< IF NEGATE THEN ;

: 0= ( n -- f )( 6.1.0270 ( 0x34 ) D# 0 = ;

: MIN ( n n -- n )( 6.1.1880 ( 0x2E ) 2DUP < IF BEGIN DROP ;
: MAX ( n n -- n )( 6.1.1870 ( 0x2F ) 2DUP < UNTIL THEN NIP ;

: WITHIN ( u ul uh -- f )( 6.2.2440 ( 0x45 ) OVER - >R - R> U< ;

: 0<> ( n -- f ) d# 0 = invert ;

: UPPER ( c -- C ) \ convert to uppercase ( upc ( 0x81 ) \ bbb
  \ DUP [CHAR] a h# 7B WITHIN IF BL XOR THEN ;
  h# 60 over < if h# 5f and then ;

\ -----------------------------------------------------------

2000 constant RAM_PAL
0 constant tib
variable >in        \ offset into TIB
variable tibsz      \ how much space remains

2892 constant dp
2895 constant BLKRDY
2896 constant COUT
2897 constant COUTRDY
2898 constant CIN

: ser-emit
    COUT c!
    d# 1 COUTRDY c!
    begin
        COUTRDY c@ 0=
    until
;

400 ivariable cursor
: vid-emit
    dup d# 10 = if
        drop cursor @ h# ffc0 and cursor !
    else
        dup d# 13 = if
            drop cursor @ h# 40 + cursor !
        else
            cursor @ tuck c! 1+ cursor !
        then
    then
;
: page
    d# 4096 d# 0 begin
        d# 0 over c!
        1+ 2dup =
    until 2drop
    h# 400 cursor !
;

: emit vid-emit ;

: space bl emit ;
: cr   d# 13 emit d# 10 emit ;

: hex1 d# 15 and dup d# 10 < if d# 48 else d# 55 then + emit ;
: hex2
    dup 
    d# 4 rshift
    hex1 hex1
;
: hex4
    dup
    d# 8 rshift
    hex2 hex2 ;
: hex8 hex4 hex4 ;
: . hex4 space ;

: snap
    [char] S emit
    [char] N emit
    [char] A emit
    [char] P emit
    cr
    hex4 cr
    hex4 cr
    hex4 cr
    hex4 cr
    hex4 cr
    hex4 cr
    hex4 cr
    hex4 cr
    begin again
;

: CHAR+ 1+ ;
: CHARS ;
: PAUSE ;

: +! ( n a -- )( 6.1.0130 ( 0x6C ) DUP >R @ + R> ! ;
: COUNT ( a -- a c )( 6.1.0980 ( 0x84 ) DUP CHAR+ SWAP C@ ;
: BOUNDS ( a u -- a+u a )( 0xAC ) OVER + SWAP ;
: /STRING ( ca u n -- ca+n u-n )( 17.6.1.0245 ) SWAP OVER - >R CHARS + R> ;
: TYPE ( ca u -- )( 6.1.2310 ( 0x90 )
  PAUSE  CHARS  BOUNDS BEGIN 2DUP XOR WHILE COUNT EMIT REPEAT 2DROP ;

: SAME? ( ca ca u -- f )
    begin
        dup
    while
        >r
        over c@ upper over c@ upper <> if
            r> drop 2drop false ;
        then
        1+ swap 1+ swap
        r> 1-
    repeat
    drop 2drop true ;


: isimmediate ( xt -- f )
    d# -3 + c@ h# 80 and 0<> ;
: name? ( xt -- ca u )
    d# -3 + dup c@ h# 7f and tuck - swap ;
: sayword ( xt -- ) 
    name? type ;

: inch
    >in @ tib + ;
: inch+1
    d# 1 >in +! ;

: execute
    fwd4 !
    + ;

: advance
    d# 1 /string d# 1 >in +! ;

: skipbl ( ca u -- ca u ) \ skip blank chars
    begin
        over c@ bl = over 0<> and
    while
        advance
    repeat
;

: skipnbl ( ca u -- ca u ) \ skip nonblank chars
    begin
        over c@ bl <> over 0<> and
    while
        advance
    repeat
;

variable source/a
variable source/l

: source ( -- ca u )( 6.1.2216 )
    source/a @ source/l @ ;
: source>in 
    source >in @ /string ;

: parse-word ( -- ca u )
    source>in
    skipbl
    over >r
    skipnbl
    drop
    r> tuck -
;


\ name
\ length
\ prev
\ cfa      <--- xt
\ args

: here  dp @ ;
: c,    here c! d# 1 dp +! ;
: ,     here ! d# 2 dp +! ;
: s,    begin dup while over c@ c, d# 1 /string repeat 2drop ;

the-link voc
0 ivariable state

: head, ( "name" -- )
    parse-word
    tuck s, c,
    voc @ , here voc !
;

: digit ( c -- u )
  upper [CHAR] 0 - D# 9 OVER <
  IF D# 7 - DUP D# 10 < OR THEN ;

: 1/string  d# 1 /string ;

: isnumber ( ca u -- f )
    \ over c@ [char] - = if 1/string then
    true >r
    begin
        dup 
    while
        over c@ digit base @ u< r> and >r
        1/string
    repeat
    2drop r>
;

: asnumber ( ca u -- false | n true )
    d# 0 >r
    begin
        dup
    while
        over c@ digit
        r> base @ * + >r
        1/string
    repeat
    2drop r> true
;

: words
    voc @
    begin
        dup
    while
        dup sayword space
        d# -2 + @
    repeat
    cr
;

: sfind ( ca u -- xt | ca u 0 )
    >r
    voc @
    begin
        dup
    while
        2dup name?  ( ca xt ca ca u )
        dup r@ = if
            SAME? if r> drop nip ; then
        else
            2drop drop
        then
        d# -2 + @
    repeat
    drop r> false
;

variable (quit)

: interpret
    begin
        parse-word
        dup
    while
        sfind ?dup if
            dup isimmediate state @ 0= or if
                execute
            else
                ,
            then
        else
            2dup isnumber if
                state @ if
                    '(lit) ,
                    asnumber drop
                    ,
                else
                    asnumber drop
                then
            else
                [char] ? emit type (quit) @ execute
            then
        then
    repeat
    2drop
;

( Gameduino system constants                 JCB 16:45 04/15/11)

0000 constant RAM_PIC       1000 constant RAM_CHR        
2000 constant RAM_PAL       2800 constant IDENT          
2801 constant REV           2802 constant FRAME       
2803 constant VBLANK        2804 constant SCROLL_X    
2806 constant SCROLL_Y      2808 constant JK_MODE                   
280a constant SPR_DISABLE   280b constant SPR_PAGE              
280c constant IOMODE        280e constant BG_COLOR              
2810 constant SAMPLE_L      2812 constant SAMPLE_R
2a00 constant VOICES        2840 constant PALETTE16A     
2860 constant PALETTE16B    2880 constant PALETTE4A      
2888 constant PALETTE4B     2890 constant COMM           
2900 constant COLLISION     2c00 constant J1_CODE        
3000 constant RAM_SPR       3800 constant RAM_SPRPAL     
4000 constant RAM_SPRIMG     
\ screen \ 11
8016 constant FLASH_MISO
8018 constant FLASH_MOSI
801a constant FLASH_SCK
801c constant FLASH_SSEL

( SPI                                        JCB 16:42 04/15/11)

: off   d# 0 swap c! ;         : on    d# 1 swap c! ;
: spi-sel       FLASH_SSEL off ;
: spi-unsel     FLASH_SSEL on ;
: spi-cold      spi-unsel FLASH_SCK off ;
: spi-1bit  ( u -- u )      \ single bit via SPI
    d# 2 *
    dup d# 8 rshift FLASH_MOSI c!   \ write MSB to MOSI
    FLASH_SCK on             \ raise clock
    FLASH_MISO c@ or         \ read MISO into LSB
    FLASH_SCK off ;          \ drop clock
: spi-xfer  ( u -- u )
    spi-1bit spi-1bit spi-1bit spi-1bit
    spi-1bit spi-1bit spi-1bit spi-1bit ;
: >spi spi-xfer drop ;

( Atmel flash                                JCB 07:32 04/16/11)

\ http://www.atmel.com/dyn/resources/prod_documents/doc3638.pdf
: flash-status  spi-sel h# D7 spi-xfer spi-xfer spi-unsel ;
: flash-ready?  begin flash-status h# 80 and until ;
: flash-page    ( u -- ) \ 512*(572+u)
    d# 572 +
    dup d# 7 rshift >spi
    d# 2 * >spi
    d# 0 >spi ;
: page>flash ( a u -- a' u' )
    spi-sel
    h# 82 >spi tuck flash-page
    d# 264 bounds begin
        dup c@ >spi
        1+ 2dup =
    until drop swap 1+ spi-unsel
    flash-ready? ;
: blk>flash ( a u -- )
    d# 4 * page>flash page>flash page>flash page>flash 2drop ;
: flash>page ( u -- )
    spi-sel
    h# 03 >spi
    flash-page
    h# 0 h# 400 bounds begin
        d# 0 spi-xfer over c!
        1+ 2dup =
    until 2drop spi-unsel ;

: interpret0
    d# 0
    begin
        >r d# 0 >in !
        r@ source/a ! d# 64 source/l ! interpret
        r> h# 40 +
        dup h# 400 =
    until drop
;

: load
    d# 4 * flash>page
    \ d# 1024 d# 0 begin dup c@ emit 1+ 2dup = until
    interpret0
;

variable blk
    
: key
    begin CIN c@ ?dup until
    d# 0 CIN c! ;

: . hex4 ;

: quit
    begin
        cr
        begin
            d# 127 emit d# -1 cursor +!
            key dup d# 13 xor
        while
            emit
        repeat
        drop
        cursor @ h# ffc0 and 
        cursor @ h# 003f and
        space
        d# 0 >in !
        source/l ! source/a ! interpret
        space
        [char] o emit
        [char] k emit
    again
;

: (
    source>in
    begin
        over c@ [char] ) <>
    while
        advance
    repeat advance 2drop ;

: nucok
    [char] N emit
    [char] U emit
    [char] C emit
    space
    [char] O emit
    [char] K emit
    cr ;

\ : sec
\     spi-sel 77 spi-xfer spi-xfer spi-xfer spi-xfer drop
\     80 begin 0 spi-xfer hex2 space next cr ;

: f;
    semis# ,
    d# 0 state ! ; immediate

: :
    head,
    bc-col c,
    d# 1 state !
;

label main
    nucok
    [char] J IOMODE c! spi-cold
    d# 0 blk !
    begin
        begin BLKRDY c@ until

        \ d# 0 blk @ blk>flash d# 1 blk +!

        interpret0
        d# 0 BLKRDY c!
    again
label blkmain
    nucok
    [char] J IOMODE c! spi-cold
    d# 0 begin
        dup >r load r> 1+
    again
label stump
    main

dumpmem
meta
