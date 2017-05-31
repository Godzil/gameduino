start-microcode setpixel

: setpixel ( yx -- ) \ set pixel yx to color from COMM+2, about 35 cycles
    dup>r
    h# f and
    r@ d# 4 rshift h# 0ff0 and or
    r@ h# 30 and swab or
    RAM_SPRIMG or ( addr )
    dupc@ ( addr v )
    h# c0 r> d# 5 rshift h# 6 and rshift dup>r \ mask in R
    invert and r> COMM+2 c@ and or
    swap c!
;

: main
    begin
        \ wait until command reg is nonzero
        begin
            COMM+2 c@
        until
        
        \ 0 is X, 1 is Y
        COMM+0 c@ COMM+1 c@ swab or
        setpixel

        \ tell host we're done
        d# 0 COMM+2 c!
    again
;

end-microcode
