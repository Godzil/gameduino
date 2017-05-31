start-microcode soundbuffer

\ Interface:
\ COMM+0    sound read pointer
\ 3F00-3FFF sound buffer

\ This microprogram provides a simple sound sample buffer.
\ It reads 8-bit samples from the buffer at 3F00-3FFF and
\ writes them to the audio sample registers SAMPLE_L and
\ SAMPLE_R.
\ The current buffer read pointer is COMM+0.

h# 3f00 constant BUFFER
[ 125 50 * ] constant CYCLE \ one cycle of 8KHz in clocks

: 1+    d# 1 + ;
: -     invert 1+ + ;

: main
    d# 0        ( when )
    begin
        CLOCK c@ over -     \ positive means CLOCK has passed `when`
        d# 0 < invert if
            COMM+0 c@ dup
            h# 3f00 + c@
            dup SAMPLE_Lhi c! SAMPLE_Rhi c!
            1+ COMM+0 c!
            CYCLE +
        then
    again
;

end-microcode
