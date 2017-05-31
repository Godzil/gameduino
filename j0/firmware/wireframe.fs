start-microcode wireframe

\ See http://en.wikipedia.org/wiki/Bresenham's_line_algorithm

COMM+0 constant X0
COMM+1 constant Y0
COMM+2 constant X1
COMM+3 constant Y1
COMM+4 constant steep
COMM+5 constant deltax
COMM+6 constant deltay
COMM+7 constant ystep
COMM+8 constant color

: setpixel ( yx -- ) \ set pixel yx to color
    dup>r
    h# f and
    r@ d# 4 rshift h# 0ff0 and or
    r@ h# 30 and swab or
    RAM_SPRIMG or ( addr )
    dupc@ ( addr v )
    color c@ r> d# 5 rshift h# 6 and rshift or
    swap c!
;

: negate invert ;fallthru
: 1+    d# 1 + ;
: @     dupc@ swap 1+ c@ swab or ;
: byte  h# ff and ;

: bresenham
    deltay c@ negate >r     \ keep -deltay on R stack for speed
    X0 @                    \ load y0x0
    deltax c@ d# 1 rshift   \ load deltax/1, is error

                    ( y0x0 error )
    begin
        over byte X1 c@ xor
    while
        over
        steep c@ if swab then
        setpixel
        r@ +                \ error -= deltay
        dup d# 0 < if
            deltax c@ +     \ error += deltax
            ystep c@ swab 1+
        else
            d# 1
        then
        >r swap r> + swap   \ increment YX
    repeat
    r> drop
;

: main
    begin
        \ wait until command reg is nonzero
        begin
            ystep c@
        until
        
        bresenham

        \ tell host we're done
        d# 0 ystep c!
    again
;

end-microcode
