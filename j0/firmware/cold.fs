start-microcode cold

\ system cold start program

\ Interface:
\ 3400-34FF voices source
\ 3800-3FFF palette animation source (64 palettes)

h# 3400 constant VOICES_COPY
h# 3800 constant PALETTES

d# 32   constant PALSZ      \ size of palette in bytes

: vblank@
        VBLANK ;fallthru
: _c@   c@ ;                \ these save 1 instruction per use
: _c!   c! ;
: 1+    d# 1 + ;
: @     dup _c@ swap 1+ _c@ swab or ;
: up1 ( a -- ) \ subtract 1 from sprite coordinate at a
        dup>r @ dup h# fe00 and swap 1- h# 1FF and or r> ;fallthru
: !     ( u addr )
        over swab over 1+ _c! _c! ;

: waitvbi   \ wait for start of vertical blanking interval
    begin vblank@ 1- until
    begin vblank@ until ;

: stepfade ( u -- ) \ fade step u is 0-63
    PALSZ * PALETTES +
    dup d# 30 + @ BG_COLOR !    \ copy 15th palette entry to BG_COLOR
    PALETTE16A
    PALSZ
;fallthru
: cmove ( src dst n -- )
    begin
        dup
    while
        >r
        over _c@ over _c!
        1+ swap 1+ swap
        r> 1-
    repeat
    drop ;fallthru
: 2drop drop drop ;

: endl ( limit u -- limit u' finished ) \ end of loop
    waitvbi ;fallthru
: qendl \ quick endl, no wait for frame
    1+
    2dup=
;

: >VOICES ( a -- ) \ load all voices from a
    VOICES d# 256 cmove ;

[ RAM_SPR 2 + ] constant SPR_YS \ sprite Y coordinates

: main
    d# 256 d# 0
    begin
        dup h# c0 and d# 128 = if
            dup d# 63 and stepfade
        then
        \ copy 3E00+u to VOICES+u
        dup VOICES_COPY + _c@
        over VOICES + _c!
    endl until
    begin 
        COMM+9 _c@
    until
    h# 3500 >VOICES 
    d# 265 d# 0
    begin
        d# 256 d# 0
        begin
            dup d# 4 * SPR_YS + up1
        qendl until
        2drop
        dup SCROLL_Y !
    endl until
    h# 3600 >VOICES 
    d# 0
    begin
        waitvbi 
        dup SCROLL_X !
        1+
    again
;

end-microcode
