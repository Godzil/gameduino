start-microcode dna

: 1+ d# 1 + ;
: 2* d# 2 * ;

: dna@      ( -- u )    h# 8018 c@ ;
: dna!      ( u -- )    h# 8008 c! ;
: dnaclk    ( u -- )    dup dna! 1+ dna! ;
: dnaread   ( )         d# 4 dnaclk ;
: dnashift  ( )         d# 2 dnaclk ;
: dnabit    ( u -- u )  2* dna@ + dnashift ;
: dnabyte   ( -- u )    \ read byte from DNA
    d# 0
    dnabit dnabit dnabit dnabit
    dnabit dnabit dnabit dnabit ;
: main       \ write 7 byte DNA to COMM
    dnaread dnashift
    COMM+7 COMM+0
    begin
        dnabyte over c!
        1+ 2dup=
    until
    begin again ;

end-microcode
