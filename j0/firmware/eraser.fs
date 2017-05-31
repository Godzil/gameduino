start-microcode eraser

COMM+8 constant mask

: main

    mask c@ >r
    h# 3FFF h# 7FFF \ RAM_SPRIMG, from top to bottom
    begin
        dupc@ r@ and
        over c!
        1- 2dup=
    until

    \ tell host we're done
    d# 0 COMM+7 c!
    \ hang
    begin again
;

end-microcode

