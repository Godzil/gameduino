start-microcode reload

\ This short microprogram forces a full chip reset, just like a power-cycle

\ it talks to the Spartan 3A's ICAP interface to cause a full FPGA reload,
\ as described in
\ http://www.xilinx.com/support/documentation/user_guides/ug332.pdf page 278

\ ICAP data bus is bit-reversed!
: rev1 ( a b -- a' b' ) d# 2 * over d# 1 and + swap d# 1 rshift swap ;
: rev8 d# 0 rev1 rev1 rev1 rev1 rev1 rev1 rev1 rev1 nip ;

\ The ICAP_PORT low 8 bits are the reversed ICAP_I byte.
\ Bits 8,9,10 are:

h# 100 constant ICAP-CLK        \ 1,0 is a pulse
h# 200 constant ICAP-CE         \ 0 means select
h# 400 constant ICAP-WRITE      \ 0 means write

: ICAP!
    ICAP_PORT c! ;

: >cicap ( v -- )    \ clock byte v into ICAP
    rev8 dup ICAP! ICAP-CLK or ICAP! ;

: >icap ( v -- ) \ 16-bit ICAP write
    dup swab >cicap >cicap ;

: icap_reload
    h# ffff >icap
    h# aa99 >icap
    h# 3261 >icap
    h# 0000 >icap
    h# 3281 >icap
    h# 0000 >icap

    h# 30a1 >icap
    h# 000e >icap
    h# 2000 >icap
    h# 2000 >icap \ needs extra NOOP to complete reboot
;

: main
    h# 0 ICAP!

    icap_reload
    begin again
;

end-microcode
