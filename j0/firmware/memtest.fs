start-microcode memtest

32 constant sp
0 constant false ( 6.2.1485 )
: true  ( 6.2.2298 ) d# -1 ;
: 1+    d# 1 + ;
: rot   >r swap r> swap ;
: -rot  swap >r swap r> ;
: 0=    d# 0 = ;
: tuck  swap over ;
: 2drop drop drop ;
: ?dup  dup if dup then ;
: 2*        d# 2 * ;

: summit
    h# 0 c@
    h# 1 c@ +
    h# 2 c@ +
    h# 3 c@ +
    h# 4 c@ +
    h# 5 c@ +
    h# 6 c@ +
    h# 7 c@ +
    h# 8 c@ +
    h# 9 c@ +
    d# 765
    \ d# 550
    over xor
    if
        h# DEAD begin again
    else
        drop
    then
;

: move ( c-addr1 c-addr2 u -- )
    begin
        >r
        over noop noop c@ over c!
        1+ swap 1+ swap
        r> 1- dup 0=
    until
    drop 2drop
;

: main
    begin
        h# 0 h# 16 d# 10 move
        h# 16 h# 0 d# 10 move
        summit
    again
;

end-microcode
