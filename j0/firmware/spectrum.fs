start-microcode spectrum

\ Interface:
\ 4000-57FF Spectrum bitmap
\ 5800-5AFF Spectrum attributes
\ 7000 attribute lookup: 256 bytes.  64 colors of (paper, ink)
\ 7100 pixel stretch, 16 bytes.

: 1+    d# 1 + ;
: 0=    d# 0 = ;
: 4*    d# 4 * ;
: 64mod h# 3f and ;

: copy1 ( src dst -- src' dst' ) \ copy one byte
    over c@
    over c!
    1+
;fallthru
: n1+  ( a b -- a+1 b )
    swap 1+ swap ;

\ copy attrs for line y
\ dst is RAM_PAL or RAM_PAL+256

: attrcopy ( y -- )
    dup 4* h# 5800 + swap            ( src y )
    h# 8 and d# 32 * RAM_PAL +       ( src dst ) 
    begin
        over c@ 64mod 4* h# 7000 + swap \ fetch and lookup attribute
        copy1 copy1 d# 4 + copy1 copy1 nip
        n1+
        dup h# ff and 0=
    until
    drop drop
;

: stretch! ( dst a -- dst' ) \ expand 4 bit graphic a, write to dst
    h# f and
    h# 7100 + c@
    over c! 1+
    ;

: byte ( src dst -- src' dst' )
    over c@ swap    ( src a dst )
                    
    over d# 4 rshift stretch!
    swap stretch!  ( src dst' )
    swap h# 100 + swap      \ down 1 line in spectrum video memory
;

: byte4
    byte byte byte byte ;

: pixelcopy ( y -- y )
    dup 64mod 4* h# 4000 +
    over h# c0 and d# 32 * +    ( y src )
    begin
        dup
        dup 64mod d# 16 * RAM_CHR +
        byte4 byte4
        drop drop
        1+
        dup h# 1f and 0=
    until drop
;

\ Spectrum memory layout is a bit twisted
\ line 0      4000, 4001, 4002
\      1      4100, 4101
\             ...
\      8      4020
\             ...
\      56     40e0, ...             40ff
\             ...
\      63     47e0                  47ff
\      64     4800
\      65     4900
\             ...
\      191    57e0

\ at line  0 can start work on 4020
\ at line  8 can start work on 4040
\ at line 16 can start work on 4060
\         56                   4800
\
\ So in general, at line Y can start work on converting from:
\ 4000 + (((Y+8) & 38) * 4) + (((y+8) & c0) * 32)

: main
    d# 0
    begin
        begin dup d# 48 + YLINE c@ = until
        d# 8 + h# ff and
        dup attrcopy
        pixelcopy
    again
;

end-microcode
