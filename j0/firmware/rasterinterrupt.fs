start-microcode rasterinterrupt

: 1+ d# 1 + ;
: @     dup c@ swap 1+ c@ swab or ;

\ COMM+0 holds the 16 bit raster line number:
\   0 is first line of screen
\ 299 is last visible line of screen
\ 300 is beginning of vertical blanking
\
\ This microprogram loop raises P2 when the raster is below line COMM+0,
\ so the Arduino can trigger an interrupt

: main
    d# 0 P2_DIR c!          \ Make P2 an output
                            \ Drive P2 high when raster is past line COMM+0
    begin
        COMM+0 @            \ user value
        YLINE c@            \ hardware line
        <                   \ true when hardware line is below user value
        P2_V c!             \ write bool to P2
    again
;

end-microcode
