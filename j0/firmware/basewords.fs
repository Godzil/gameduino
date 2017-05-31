( Base words implemented in assembler        JCB 13:10 08/24/10)

meta
: noop      T                       alu ;
: +         T+N                 d-1 alu ;
: xor       T^N                 d-1 alu ;
: and       T&N                 d-1 alu ;
: or        T|N                 d-1 alu ;
: invert    ~T                      alu ;
: =         N==T                d-1 alu ;
: <         N<T                 d-1 alu ;
: u<        Nu<T                d-1 alu ;
: swap      N     T->N              alu ;
: dup       T     T->N          d+1 alu ;
: drop      N                   d-1 alu ;
: over      N     T->N          d+1 alu ;
: nip       T                   d-1 alu ;
: >r        N     T->R      r+1 d-1 alu ;
: r>        rT    T->N      r-1 d+1 alu ;
: r@        rT    T->N          d+1 alu ;
: c@        T                       alu
            [T]                     alu ;
: c!        T     N->[T]        d-1 alu
            N                   d-1 alu ;
: rshift    N>>T                d-1 alu ;
: *         N*T                 d-1 alu ;
: swab      swabT                   alu ;
: 1-        T-1                     alu ;
: exit      return                      ;

\ Elided words
\ These words are supported by the hardware but are not
\ part of ANS Forth.  They are named after the word-pair
\ that matches their effect  The first word is one of
\ 2dup, dup or over.  Using these elided words instead of
\ the pair saves one cycle and one instruction.

: 2dupand   T&N   T->N          d+1 alu ;
: 2dup<     N<T   T->N          d+1 alu ;
: 2dup=     N==T  T->N          d+1 alu ;
: 2dup*     N*T   T->N          d+1 alu ;
: 2dupor    T|N   T->N          d+1 alu ;
: 2duprshift N>>T T->N          d+1 alu ;
: 2dup+     T+N   T->N          d+1 alu ;
: 2dupu<    Nu<T  T->N          d+1 alu ;
: 2dupxor   T^N   T->N          d+1 alu ;
: dup>r     T     T->R          r+1 alu ;
: dupc@     T     T->N          d+1 alu
            [T]                     alu ;
: dupswab   swabT T->N          d+1 alu ;
: overand   T&N                     alu ;
: over>     N<T                     alu ;
: over=     N==T                    alu ;
: over*     N*T                     alu ;
: overor    T|N                     alu ;
: over+     T+N                     alu ;
: overu>    Nu<T                    alu ;
: overxor   T^N                     alu ;

: module[ there [char] " parse preserve ;
: ]module s" Compiled " type count type space there swap - . cr ;
