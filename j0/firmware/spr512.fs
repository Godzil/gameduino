start-microcode spr512

: main
    begin
        d# 150
        YLINE c@
        <
        SPR_PAGE c!
    again
;

end-microcode

