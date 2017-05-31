start-microcode regressfreq

\ Reads 16-bit frequency from COMM, generates square
\ wave at half frequency PIN2

: 1+    d# 1 + ;
: @     dup c@ swap 1+ c@ swab or ;
: !     over swab over 1+ c! c! ;

: main
    d# 0 P2_DIR c!          \ Make P2 an output
                            \ Drive P2 high when raster is past line COMM+0
    COMM+0 @ FREQHZ c!
    begin
        FREQTICK c@ P2_V c!
    again
;

end-microcode
