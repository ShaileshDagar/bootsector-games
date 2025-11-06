use16

org 07C00h

jmp setup_game

;; CONSTANTS -----------------
VIDMEM          equ 0B800h                          ; color text mode VGA memory location
ROWLEN          equ 160                             ; 80 character row * 2 bytes each
PLAYERX         equ 4
CPUX            equ 154                             ; Keyboard scancodes
KEY_W           equ 11h
KEY_S           equ 1Fh
KEY_C           equ 2Eh
KEY_R           equ 13h
SCREENW         equ 80
SCREENH         equ 25
PADDLEHEIGHT    equ 5

;; Variables -----------------
drawColor:  db 0F0h
playerY:    dw 10
cpuY:       dw 10
ballX:      dw 66
ballY:      dw 7

setup_game:
    mov ax, 0003h                           ; AL = 03H text mode 80x25 characters, 16 color VGA
    int 10h

    ;; Set up video memory
    mov ax, VIDMEM
    mov es, ax

game_loop:

    ;; Clear screen to black every loop
    xor ax, ax
    xor di, di
    mov cx, 80*25
    rep stosw

    ;; Draw middle separating line
    mov ah, [drawColor]                     ; White bg, black fg
    mov di, 39*2                            ; 39th column, each column is 2 Bytes
    mov cx, 13                              ; Drawing every other row
    .draw_middle_loop:
        stosw
        add di, 2*ROWLEN - 2                ; Only drawing every other row, subtracting 2 to because loop increments
        loop .draw_middle_loop

    ;; Draw Player Paddle
    imul di, [playerY], ROWLEN              ; Y position is Y (# of rows) * length or row
    imul bx, [cpuY], ROWLEN
    mov cl, PADDLEHEIGHT
    .draw_player_loop:
        mov [es:di+PLAYERX], ax
        mov [es:bx+CPUX], ax
        add di, ROWLEN
        add bx, ROWLEN
        loop .draw_player_loop

    ;; Draw Ball
    imul di, [ballY], ROWLEN
    add di, [ballX]
    mov word [es:di], 2000h
    
    ;; Get Player Input
    mov ah, 1                               ; BIOS get keyboard status int 16h AH 01h
    int 16h
    jz move_cpu

    cbw                                     ; zero out AH if AL < 128 (single byte instruction)
    int 16h                                 ; Get keystroke in AX; AH = scancode; AL = ASCII value

    cmp ah, KEY_W
    je w_pressed
    cmp ah, KEY_S
    je s_pressed
    cmp ah, KEY_C
    je c_pressed
    cmp ah, KEY_R
    je r_pressed

    jmp move_cpu                            ; user pressed some other key, we'll ignore and move on


    ;; Move Player Paddle
    w_pressed:
        dec word [playerY]                  ; Move up 1 row
        jge move_cpu                        ; If playerY is greater than or equal to 0, then move on
        inc word [playerY]
        jmp move_cpu

    s_pressed:
        cmp word [playerY], SCREENH-PADDLEHEIGHT
        jge move_cpu
        inc word [playerY]                  ; Move down by 1 row
        jmp move_cpu

    c_pressed:
    r_pressed:


    ;; Move CPU
    move_cpu:

    ;; Move Ball

    ;; Delay loop
    mov bx, [046Ch]
    inc bx
    inc bx
    .delay:
        cmp [046Ch], bx
        jl .delay


jmp game_loop

;; Win/Lose condition

times 510 -($-$$) db 0                      ; Bootsector padding
dw 0AA55h                                   ; Bootsector Signature