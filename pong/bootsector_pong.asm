use16

org 07C00h

jmp setup_game

;; CONSTANTS -----------------
VIDMEM  equ 0B800h                          ; color text mode VGA memory location
ROWLEN  equ 160                             ; 80 character row * 2 bytes each
PLAYERX equ 4
CPUX    equ 154

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
    add di, PLAYERX
    mov cl, 5
    .draw_player_loop:
        stosw
        add di, ROWLEN - 2
        loop .draw_player_loop

    ;; Draw CPU Paddle
    imul di, [cpuY], ROWLEN
    mov cl, 5
    .draw_cpu_paddle:
        mov [es:di+CPUX], ax
        add di, ROWLEN
        loop .draw_cpu_paddle

    ;; Draw Ball
    imul di, [ballY], ROWLEN
    add di, [ballX]
    mov word [es:di], 2000h
    
    ;; Get Player Input

    ;; Move CPU

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