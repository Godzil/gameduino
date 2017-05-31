( 00:                                        JCB 08:33 04/24/11)
: immediate voc @ 3 - dup c@ 80 or swap c! f;
: ; semis# , 0 state ! f; immediate
: exit semis# , ; immediate
: \ source nip >in ! ; immediate
: allot     dp +! ;
: create    head, bc-var# c, ;
: variable  head, bc-var# c, 0 , ;
: 2variable head, bc-var# c, 0 , 0 , ;
: constant  head, bc-const# c, , ;
: compile,  , ;
: cell+ 2 + ;  : 2* 2 * ; : cells 2* ;

( 01: branching                              JCB 08:15 04/24/11)
: ahead     branch# , here 7777 , ;
: 0ahead    0branch# , here 7777 , ;
: resolve   here swap ! ; \ resolve stacked ref to HERE
: begin     here ; immediate
: again     branch# , , ; immediate
: until     0branch# , , ; immediate
: while     0ahead ; immediate
: repeat    swap branch# , , resolve ; immediate
: if        0ahead ; immediate
: else      ahead swap resolve ; immediate
: then      resolve ; immediate

( 02: parse                                  JCB 08:16 04/24/11)
: parse \ ( char -- ca u )
    source>in
    advance
    over >r
    rot >r
    begin
        over c@ r@ <> over 0<> and
    while
        advance
    repeat
    r> 2drop
    r> tuck - 1 >in +!
;

( 03: compilation                            JCB 08:17 04/24/11)
: [         0 state ! ; immediate
: ]         1 state ! ;
: literal   literal# , , ; immediate
: char      parse-word drop c@ ;
: '         parse-word sfind ;
: [']       literal# , ' , ; immediate
: postpone
    parse-word sfind
    dup isimmediate invert if
        literal# , , ['] ,
    then , ; immediate
: [char]    char postpone literal ; immediate
: (         [char] ) parse 2drop ; immediate
: halt      begin again ;  ' halt (quit) !

( 04: debug                                  JCB 08:17 04/24/11)
: dump 
    over hex4 bounds
    begin 2dup xor
    while space dup c@ hex2 1+
    repeat 2drop cr ;
: isxt voc @ begin 2dup = if 2drop true exit then
    2 - @ dup 0= until nip ;
: typext dup isxt if name? type else hex4 then ;
: seelast   [char] : emit space voc @ name? type
    here voc @ 1+ begin
        2dup xor
    while space dup @ typext cell+
    repeat cr 2drop ;

( 05: strings                                JCB 08:17 04/24/11)
: (sliteral)
    r> count 2dup + >r ;
: s"
    [char] " parse
    postpone (sliteral) dup c, s, ; immediate
: ." postpone s" postpone type ; immediate
: .( [char] ) parse type cr ; immediate
: (next)    1- ?dup 0= ;
: next      postpone (next) postpone until ; immediate

( 06: move                                   JCB 08:18 04/24/11)
: cmove ( c-addr1 c-addr2 u -- )
    begin
        dup
    while
        >r over c@ over c!
        1+ swap 1+ swap
        r> 1-
    repeat
    drop 2drop
;

( 07: create does>                           JCB 08:18 04/24/11)
: (create)  r> cell+ ;
: (does)    r> dup cell+ swap @ >r ;
: create
    head, bc-col# c,
    ['] (create) , 0 , ;
: does>
    r> voc @ 1+
    ['] (does) over ! cell+ ! ;
: :noname
    here bc-col# c, ] ;

( 08: welcome                                JCB 08:18 04/24/11)
\ screen \ 8
.( gdforth 0.0.1)
here hex4 cr
' quit (quit) !

( 09: DNA                                    JCB 08:19 04/24/11)
: dna@      ( -- u )    8018 c@ ;
: dna!      ( u -- )    8008 c! ;
: dnaclk    ( u -- )    dup dna! 1+ dna! ;
: dnaread   ( )         4 dnaclk ;
: dnashift  ( )         2 dnaclk ;
: dnabit    ( u -- u )  2* dna@ + dnashift ;
: dnabyte   ( -- u )    \ read byte from DNA
    0 8 begin >r dnabit r> next ;
: dna       ( ca -- )   \ write 7 byte DNA at ca
    dnaread dnashift
    7 begin
        >r dnabyte over c! 1+ r>
    next drop ;
\ 7F00 dna 7F00 7 dump
( 10: SPI and flash                          JCB 08:19 04/24/11)
char J IOMODE c!  spi-cold
\ flash-status hex2 cr
: showblk ( u -- )
    spi-sel
    03 >spi
    flash-page
    400 400 bounds begin
        0 spi-xfer over c!
        1+ 2dup =
    until 2drop spi-unsel ;
\ 0 showblk
\ here hex4 cr
quit
