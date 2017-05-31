start-microcode bgstripes

\ renders a 64-line horizontal stripe in the BG_COLOR
\ starting at line COMM+0

\ Interface:
\ COMM+0    stripe start
\ 3E80-3EFF 64 color stripe

: 1+    d# 1 + ;
: -     invert 1+ + ;
: 0=    d# 0 = ;
: @     dup c@ swap 1+ c@ swab or ;
: !     over swab over 1+ c! c! ;
: 2dup  over over ;
: min   2dup < ;fallthru
: ?:    ( xt xf flag -- xt | xf)    \ if flag xt, else xf
        if drop else nip then ;
: max   2dup swap < ?: ;

: main
    begin
        YLINE c@            \ line COMM+0 is line zero
        COMM+0 c@ -
        d# 0 max d# 63 min  \ clamp to 0-63
        d# 2 * h# 3E80 +    \ index into color table
        @ BG_COLOR !        \ fetch and write
    again
;

end-microcode

