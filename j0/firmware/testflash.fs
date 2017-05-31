start-microcode testflash

: off   d# 0 swap c! ;
: on    d# 1 swap c! ;

: spi-sel       FLASH_SSEL off ;
: spi-unsel     FLASH_SSEL on ;
: spi-cold      spi-unsel FLASH_SCK off ;

: spi-1bit  ( u -- u )      \ single bit via SPI
    d# 2 *
    dup swab FLASH_MOSI c!   \ write MSB to MOSI
    FLASH_SCK on             \ raise clock
    FLASH_MISO c@ or         \ read MISO into LSB
    FLASH_SCK off ;          \ drop clock

: spi-xfer  ( u -- u )
    spi-1bit
    spi-1bit
    spi-1bit
    spi-1bit
    spi-1bit
    spi-1bit
    spi-1bit
    spi-1bit ;

\ See Atmel AT45DB021D datasheet:
\ http://www.atmel.com/dyn/resources/prod_documents/doc3638.pdf

: main
    spi-cold
    spi-sel
    h# d7 spi-xfer      \ flash read status command
    spi-xfer            \ send junk, receive status
    spi-unsel

    COMM+0 c!           \ write status to COMM+0

    begin again         
;

end-microcode
