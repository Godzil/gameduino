( Hardware register definitions              JCB 11:36 01/23/11)

h# 0000 constant RAM_PIC        \ Screen Picture, 64 x 64 = 4096 bytes
h# 1000 constant RAM_CHR        \ Screen Characters, 256 x 16 = 4096 bytes
h# 2000 constant RAM_PAL        \ Screen Character Palette, 256 x 8 = 2048 bytes
h# 2800 constant IDENT
h# 2801 constant REV
h# 2802 constant FRAME       
h# 2803 constant VBLANK      
h# 2804 constant SCROLL_X    
h# 2805 constant SCROLL_Xhi
h# 2806 constant SCROLL_Y    
h# 2807 constant SCROLL_Yhi
h# 2808 constant JK_MODE     
h# 2809 constant J1_RESET
h# 280a constant SPR_DISABLE
h# 280b constant SPR_PAGE
h# 280c constant IOMODE
h# 280e constant BG_COLOR
h# 2810 constant SAMPLE_Llo
h# 2811 constant SAMPLE_Lhi
h# 2812 constant SAMPLE_Rlo
h# 2813 constant SAMPLE_Rhi

h# 2a00 constant VOICES      
h# 2840 constant PALETTE16A     \ 16-color palette RAM A, 32 bytes
h# 2860 constant PALETTE16B     \ 16-color palette RAM B, 32 bytes
h# 2880 constant PALETTE4A      \ 4-color palette RAM A, 8 bytes
h# 2888 constant PALETTE4B      \ 4-color palette RAM A, 8 bytes
h# 2890 constant COMM           \ Communication buffer
h# 2900 constant COLLISION      \ Collision detection RAM, 256 bytes
h# 2b00 constant J1_CODE        \ J1 coprocessor microcode RAM
h# 3000 constant RAM_SPR        \ Sprite Control, 512 x 4 = 2048 bytes
h# 3800 constant RAM_SPRPAL     \ Sprite Palettes, 4 x 256 = 2048 bytes
h# 4000 constant RAM_SPRIMG     \ Sprite Image, 64 x 256 = 16384 bytes

[ COMM 0 + ] constant COMM+0
[ COMM 1 + ] constant COMM+1
[ COMM 2 + ] constant COMM+2
[ COMM 3 + ] constant COMM+3
[ COMM 4 + ] constant COMM+4
[ COMM 5 + ] constant COMM+5
[ COMM 6 + ] constant COMM+6
[ COMM 7 + ] constant COMM+7
[ COMM 8 + ] constant COMM+8
[ COMM 9 + ] constant COMM+9
[ COMM 10 + ] constant COMM+10
[ COMM 11 + ] constant COMM+11
[ COMM 12 + ] constant COMM+12
[ COMM 13 + ] constant COMM+13
[ COMM 14 + ] constant COMM+14
[ COMM 15 + ] constant COMM+15

( Locations for coprocessor only             JCB 11:45 02/06/11)

h# 8000 constant YLINE
h# 8002 constant ICAP_O
h# 8004 constant ICAP_BUSY
h# 8006 constant ICAP_PORT      \ see reload.fs for details
h# 800a constant FREQHZ
h# 800c constant FREQTICK
h# 800e constant P2_V
h# 8010 constant P2_DIR
h# 8012 constant RANDOM
h# 8014 constant CLOCK
h# 8016 constant FLASH_MISO
h# 8018 constant FLASH_MOSI
h# 801a constant FLASH_SCK
h# 801c constant FLASH_SSEL
