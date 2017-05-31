start-microcode flowtest

: main
    begin
        \ wait until COMM+0 is nonzero
        begin
            COMM+0 c@
        until

        \ increment COMM+1
        COMM+1 c@ d# 1 + COMM+1 c!

        \ write zero to COMM+0, telling host we're done
        d# 0 COMM+0 c!
    again
;

end-microcode
