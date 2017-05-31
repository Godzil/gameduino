start-microcode palcopy

: 1+ d# 1 + ;

: main
    \ Copy RAM_PAL to PALETTE16A
    RAM_PAL PALETTE16A
    d# 32
    begin
        >r
        over c@ over c!
        1+ swap 1+ swap
        r> 1- d# 0 =
    until
    begin again
;

end-microcode
