start-microcode splitscreen

: 1+    d# 1 + ;
: @     dupc@ swap 1+ c@ swab or ;

: waitline ( u -- ) \ wait until raster is past u
    begin
        dup YLINE c@ =
    until
    drop
;

: loadscroll ( a -- ) \ load SCROLL_X,Y from a
    dup c@ SCROLL_X c! 1+
    dup c@ SCROLL_Xhi c! 1+
    dup c@ SCROLL_Y c! 1+
    c@ dup SCROLL_Yhi c!
    d# 7 rshift SPR_DISABLE c!
;

: main
    begin
        COMM+4 @  waitline  COMM+6 loadscroll
        COMM+10 @ waitline  COMM+12 loadscroll
        d# 300 waitline     COMM+0 loadscroll
    again
;

end-microcode
