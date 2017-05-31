start-microcode helloworld
: 1+ d# 1 + ;
: writechar ( addr ch -- addr' )
    over c! 1+ ;

: main
    d# 512             \ lines are 64 characters, so this is line 8
    [char] H writechar
    [char] E writechar
    [char] L writechar
    [char] L writechar
    [char] O writechar
    1+
    [char] W writechar
    [char] O writechar
    [char] R writechar
    [char] L writechar
    [char] D writechar
    begin again
;

end-microcode
