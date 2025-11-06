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
ballVelX:   db -1
ballVelY:   db 1

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

    ;; Draw Player Paddles
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
    jz move_cpu_up

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

    jmp move_cpu_up                         ; user pressed some other key, we'll ignore and move on


    ;; Move Player Paddle
    w_pressed:
        dec word [playerY]                  ; Move up 1 row
        jge move_cpu_up                        ; If playerY is greater than or equal to 0, then move on
        inc word [playerY]
        jmp move_cpu_up

    s_pressed:
        cmp word [playerY], SCREENH-PADDLEHEIGHT
        jge move_cpu_up
        inc word [playerY]                  ; Move down by 1 row
        jmp move_cpu_up

    c_pressed:
        ;; Change color of the Middle line and Paddles
        add byte [drawColor], 10h           ; Move to next VGA color
        jmp move_cpu_up

    r_pressed:
        ;; reset
        int 19h


    ;; Move CPU
    move_cpu_up:
        mov bx, [cpuY]
        cmp bx, [ballY]
        jl move_cpu_down
        dec word [cpuY]
        jnz move_ball
        inc word [cpuY]

    move_cpu_down:
        add bx, PADDLEHEIGHT
        cmp bx, [ballY]
        jg move_ball
        inc word [cpuY]
        cmp word [cpuY], SCREENH
        jl move_ball
        dec word [cpuY]


    ;; Move Ball
    move_ball:
        ;; Draw Ball at current position
        imul di, [ballY], ROWLEN
        add di, [ballX]
        mov word [es:di], 2020h

        ;; Move ball to next value
        mov bl, [ballVelX]
        add [ballX], bl
        mov bl, [ballVelY]
        add [ballY], bl

    ;; Check collision
    check_hit_top:
        cmp word [ballX], 0
        jg check_hit_bottom
        neg byte [ballVelY]
        jmp end_collision_checks

    check_hit_bottom:
        cmp word [ballY], SCREENH - 1
        jl check_hit_player
        neg byte [ballVelY]
        jmp end_collision_checks

    check_hit_player:
        cmp word [ballX], PLAYERX
        jne check_hit_cpu
        mov bx, [playerY]
        cmp bx, [ballY]
        jg check_hit_cpu
        
        add bx, PADDLEHEIGHT
        cmp bx, [ballY]
        jl check_hit_cpu            ;; see if it should be jle

        neg byte [ballVelX]
        jmp end_collision_checks

    check_hit_cpu:
        cmp word [ballX], CPUX
        jne end_collision_checks
        mov bx, [cpuY]
        cmp bx, [ballY]
        jg end_collision_checks

        add bx, PADDLEHEIGHT
        cmp bx, [ballY]
        jl end_collision_checks     ;; see if should be jle

        neg byte [ballVelX]

    
    end_collision_checks:
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