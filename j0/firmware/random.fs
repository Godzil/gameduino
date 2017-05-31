start-microcode random

\ Fill PICTURE and CHARACTER RAM with random numbers

: main
    d# 0
    begin
        RANDOM c@ over c!
        1-
        h# 1FFF and
    again
;

end-microcode
