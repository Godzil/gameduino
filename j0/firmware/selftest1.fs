start-microcode selftest1
: 1+ d# 1 + ;
: ! ( u addr )
    over swab over 1+ c! c! ;
: d1+
    swap 1+
    swap over
    d# 0 = if
        1+
    then
;

\ increment COMM+0,1,2,3 until COMM+15 goes high
: main
    h# 0.
    begin
        over COMM+0 !
        dup COMM+2 !
        d1+
        begin COMM+15 c@ until
    again
;

end-microcode
