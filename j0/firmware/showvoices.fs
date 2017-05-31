start-microcode showvoices

\ continuously move sprites 0-63 to match amplitude of the
\ 64 sound voices.

: main
    d# 0
    begin
        dup d# 4 * VOICES + d# 2 + c@   \ read voice amplitude
        invert
        over d# 4 * RAM_SPR + d# 2 + c! \ write as sprite Y coord
        1- h# 3f and                    \ next voice
    again
;

end-microcode

